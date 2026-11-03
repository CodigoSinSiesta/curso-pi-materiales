// Vuelve a un punto de una sesión por RPC, sin llamar al modelo: lista tus mensajes y se queda justo antes del último.
// Abrir una sesión escribe en su fichero: úsalo siempre sobre una copia, nunca sobre la original.
// Uso: node rpc-bifurcar.mjs pi|omp <copia.jsonl>
import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname } from "node:path";

const [harness, copia] = process.argv.slice(2);
const args = harness === "pi"
  ? ["--mode", "rpc", "--offline", "--no-skills", "--no-extensions", "--session-dir", dirname(copia)]
  : ["--mode", "rpc", "--no-skills", "--no-extensions", "--no-title", "--resume", copia, "--session-dir", dirname(copia)];
const agente = spawn(harness, args, { stdio: ["pipe", "pipe", "inherit"] });

// Las respuestas llegan mezcladas con eventos y no siempre en orden: cada orden espera la suya por su id.
const pendientes = new Map();
let resto = "", n = 0;
agente.stdout.on("data", (trozo) => {
  resto += trozo;
  for (let i; (i = resto.indexOf("\n")) >= 0; ) {
    const linea = resto.slice(0, i); resto = resto.slice(i + 1);
    let r; try { r = JSON.parse(linea); } catch { continue; }
    if (r.type === "response" && pendientes.has(r.id)) { pendientes.get(r.id)(r); pendientes.delete(r.id); }
  }
});
const orden = (o) => new Promise((ok) => { const id = String(++n); pendientes.set(id, ok); agente.stdin.write(JSON.stringify({ id, ...o }) + "\n"); });
const corto = (t) => t.replace(/\s+/g, " ").slice(0, 70);

if (harness === "pi") {
  await orden({ type: "switch_session", sessionPath: copia });
  const { data } = await orden({ type: "get_fork_messages" });
  data.messages.forEach((m) => console.log(`${m.entryId}  ${corto(m.text)}`));
  const ultimo = data.messages.at(-1);
  const fork = await orden({ type: "fork", entryId: ultimo.entryId });
  const estado = await orden({ type: "get_state" });
  console.log(`\nfork de ${ultimo.entryId}: sesión nueva ${estado.data.sessionFile}`);
  console.log(`acaba justo antes de tu mensaje, que vuelve para reenviarlo: «${corto(fork.data.text)}»`);
} else {
  // omp no tiene get_fork_messages: los mensajes del usuario se leen del fichero.
  const usuario = readFileSync(copia, "utf8").trim().split("\n").map((l) => JSON.parse(l))
    .filter((e) => e.type === "message" && e.message.role === "user");
  const texto = (e) => [].concat(e.message.content).map((c) => c.text ?? c).join("");
  usuario.forEach((e) => console.log(`${e.id}  ${corto(texto(e))}`));
  const ultimo = usuario.at(-1);
  const nav = await orden({ type: "navigate_tree", entryId: ultimo.id });
  const { data } = await orden({ type: "get_messages" });
  console.log(`\nnavigate_tree a ${ultimo.id}: quedan ${data.messages.length} mensajes en la rama`);
  console.log(`el tuyo vuelve al editor para reenviarlo: «${corto(nav.data.editorText ?? "")}»`);
}
agente.stdin.end();
