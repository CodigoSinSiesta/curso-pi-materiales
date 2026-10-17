// Cliente RPC mínimo: muestra la respuesta y contesta los diálogos de permisos.
import { spawn } from "node:child_process";
import { StringDecoder } from "node:string_decoder";
import { createInterface } from "node:readline/promises";

const teclado = createInterface({ input: process.stdin, output: process.stdout });
const pi = spawn("pi", ["--mode", "rpc", "--no-session", "--no-skills",
  "-e", `${process.env.HOME}/csn/extensiones/permisos.ts`], { stdio: ["pipe", "pipe", "inherit"] });
const enviar = (r) => pi.stdin.write(JSON.stringify(r) + "\n");

// Pi escribe JSONL: se corta solo por "\n" (nada de readline sobre su salida).
const decoder = new StringDecoder("utf8");
let resto = "";
pi.stdout.on("data", (trozo) => {
  resto += decoder.write(trozo);
  for (let i; (i = resto.indexOf("\n")) >= 0; ) {
    const linea = resto.slice(0, i).replace(/\r$/, "");
    resto = resto.slice(i + 1);
    if (linea) atender(JSON.parse(linea));
  }
});

async function atender(r) {
  if (r.type === "message_update" && r.assistantMessageEvent?.type === "text_delta") {
    process.stdout.write(r.assistantMessageEvent.delta);
  } else if (r.type === "tool_execution_start") {
    console.log(`\n[${r.toolName}]`);
  } else if (r.type === "extension_ui_request" && r.method === "setStatus") {
    console.log(`\n(${r.statusText ?? ""})`);
  } else if (r.type === "extension_ui_request" && r.method === "select") {
    const si = await teclado.question(`\n${r.title}\n¿Permitir? (s/n) `);
    enviar({ type: "extension_ui_response", id: r.id, value: si === "s" ? "Permitir" : "Bloquear" });
  } else if (r.type === "agent_settled") {
    teclado.close();
    pi.stdin.end();
  }
}

enviar({ id: "1", type: "prompt", message: process.argv[2] });
