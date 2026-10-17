// Cliente RPC mínimo para oh my pi: muestra la respuesta, contesta las aprobaciones y pide las estadísticas.
import { spawn } from "node:child_process";
import { StringDecoder } from "node:string_decoder";
import { createInterface } from "node:readline/promises";

const teclado = createInterface({ input: process.stdin, output: process.stdout });
const omp = spawn("omp", ["--profile", "demo", "--mode", "rpc", "--no-session"],
  { stdio: ["pipe", "pipe", "inherit"] });
const enviar = (r) => omp.stdin.write(JSON.stringify(r) + "\n");

const decoder = new StringDecoder("utf8");
let resto = "";
omp.stdout.on("data", (trozo) => {
  resto += decoder.write(trozo);
  for (let i; (i = resto.indexOf("\n")) >= 0; ) {
    const linea = resto.slice(0, i).replace(/\r$/, "");
    resto = resto.slice(i + 1);
    if (linea) atender(JSON.parse(linea));
  }
});

async function atender(r) {
  if (r.type === "ready") {
    enviar({ id: "1", type: "prompt", message: process.argv[2] });
  } else if (r.type === "message_update" && r.assistantMessageEvent?.type === "text_delta") {
    process.stdout.write(r.assistantMessageEvent.delta);
  } else if (r.type === "tool_execution_start") {
    console.log(`\n[${r.toolName}]`);
  } else if (r.type === "extension_ui_request" && r.method === "select") {
    const si = await teclado.question(`\n${r.title}\n¿Aprobar? (s/n) `);
    enviar({ type: "extension_ui_response", id: r.id, value: si === "s" ? "Approve" : "Deny" });
  } else if (r.type === "session_settled") {
    enviar({ id: "2", type: "get_session_stats" });
  } else if (r.type === "response" && r.id === "2") {
    const { tokens, cost, toolCalls } = r.data;
    console.log(`\n(${toolCalls} herramientas · ${tokens.total} tokens · coste ${cost})`);
    teclado.close();
    omp.stdin.end();
  }
}
