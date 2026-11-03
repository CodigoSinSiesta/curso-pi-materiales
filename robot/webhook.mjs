// Receptor del webhook del robot: POST /encargo con {"ticket":"ticket-NNN"} y «Authorization: Bearer $ROBOT_TOKEN».
// Comprueba antes de lanzar nada, contesta enseguida (202) y deja el trabajo a lanzar.sh en segundo plano.
// Escucha solo en esta máquina. Uso: ROBOT_TOKEN=… node webhook.mjs
import http from "node:http";
import { spawn, spawnSync } from "node:child_process";
import { appendFileSync } from "node:fs";
import { timingSafeEqual, createHash } from "node:crypto";

const DIR = new URL(".", import.meta.url).pathname;
const TOKEN = process.env.ROBOT_TOKEN;
if (!TOKEN) throw new Error("Falta ROBOT_TOKEN");
const huella = (t) => createHash("sha256").update(t).digest();   // mismo tamaño: comparación en tiempo constante
const log = (linea) => appendFileSync(`${DIR}registro/webhook.log`, `${new Date().toISOString()} ${linea}\n`);
const responder = (res, codigo, cuerpo) => {
  res.writeHead(codigo, { "content-type": "application/json" }).end(JSON.stringify(cuerpo) + "\n");
  log(`${codigo} ${JSON.stringify(cuerpo)}`);
};

http.createServer((req, res) => {
  if (req.method !== "POST" || req.url !== "/encargo") return responder(res, 404, { error: "no existe" });
  const auth = (req.headers.authorization ?? "").replace(/^Bearer /, "");
  if (!timingSafeEqual(huella(auth), huella(TOKEN))) return responder(res, 401, { error: "no autorizado" });
  let cuerpo = "";
  req.on("data", (c) => { cuerpo += c; if (cuerpo.length > 1000) req.destroy(); });
  req.on("end", () => {
    let ticket;
    try { ticket = JSON.parse(cuerpo).ticket; } catch {}
    // Un identificador, nunca texto libre: el encargo sale de funcionalidades.json, no de la petición.
    if (typeof ticket !== "string" || !/^ticket-\d{3}$/.test(ticket)) return responder(res, 400, { error: "petición incorrecta" });
    const prueba = spawnSync(`${DIR}lanzar.sh`, ["--comprobar", ticket], { encoding: "utf8" });
    if (prueba.status === 5) return responder(res, 503, { error: "ocupado" });
    if (prueba.status !== 0) return responder(res, 409, { error: "conflicto", detalle: prueba.stdout.trim().replace(/^[^:]*: /, "") });
    const id = `${new Date().toISOString().replace(/\D/g, "").slice(0, 8)}-${new Date().toTimeString().slice(0, 8).replace(/:/g, "")}-web`;
    spawn(`${DIR}lanzar.sh`, [ticket], { detached: true, stdio: "ignore", env: { ...process.env, ROBOT_DISPARADOR: "webhook", ROBOT_ID: id } }).unref();
    responder(res, 202, { aceptado: ticket, id });
  });
}).listen(8787, "127.0.0.1", () => log("escuchando en 127.0.0.1:8787"));
