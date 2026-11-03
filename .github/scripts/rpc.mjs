// Arranca un agente en modo RPC, le manda unas órdenes que no necesitan modelo, recoge lo que contesta y lo cierra.
// Uso: node rpc.mjs <salida> '<orden JSON>[\n<orden JSON>…]' <comando> [argumentos…]
// Deja los eventos en <salida> (JSONL), la salida de error en <salida>.err y sale con el código del agente
// (124 si no contesta a tiempo). Ninguna orden es un prompt: el modelo no llega a llamarse.
import { spawn } from "node:child_process";
import { writeFileSync } from "node:fs";
import { StringDecoder } from "node:string_decoder";

const [salida, ordenes, comando, ...args] = process.argv.slice(2);
const pendientes = new Set();
const lineas = [];
let err = "";

const hijo = spawn(comando, args, { stdio: ["pipe", "pipe", "pipe"] });
const decoder = new StringDecoder("utf8");
let resto = "";
let enviadas = false;

function enviar() {
  if (enviadas) return;
  enviadas = true;
  for (const orden of ordenes.split("\n").filter(Boolean)) {
    const { id } = JSON.parse(orden);
    if (id) pendientes.add(id);
    hijo.stdin.write(orden + "\n");
  }
  if (!pendientes.size) cerrar();
}

// Tras la última respuesta se espera un poco: las extensiones avisan en session_start, a veces después.
let cerrando = false;
function cerrar() {
  if (cerrando) return;
  cerrando = true;
  setTimeout(() => hijo.stdin.end(), 1500);
}

hijo.stdout.on("data", (trozo) => {
  resto += decoder.write(trozo);
  for (let i; (i = resto.indexOf("\n")) >= 0; ) {
    const linea = resto.slice(0, i).replace(/\r$/, "");
    resto = resto.slice(i + 1);
    if (!linea) continue;
    lineas.push(linea);
    let r;
    try { r = JSON.parse(linea); } catch { continue; }
    if (r.type === "ready") enviar(); // oh my pi avisa cuando está listo; Pi no
    if (r.type === "response" && pendientes.delete(r.id) && !pendientes.size) cerrar();
  }
});
hijo.stderr.on("data", (trozo) => { err += trozo; });
hijo.on("error", (e) => { err += String(e); });

// Pi no manda «ready»: si en 3 s no ha llegado, se envían igual.
setTimeout(enviar, 3000);
const limite = setTimeout(() => { err += "\n(rpc.mjs: sin respuesta en 60 s)"; hijo.kill("SIGKILL"); }, 60_000);

hijo.on("close", (codigo, senal) => {
  clearTimeout(limite);
  writeFileSync(salida, lineas.join("\n") + (lineas.length ? "\n" : ""));
  writeFileSync(`${salida}.err`, err);
  process.exit(senal ? 124 : (codigo ?? 1));
});
