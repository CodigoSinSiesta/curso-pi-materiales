import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const run = promisify(execFile);

// El pie muestra el último resultado de ejecutar_tests en la rama activa, leído de su details.
function reconstruir(ctx: ExtensionContext) {
  let ultimo: { pasan: number; fallan: number } | undefined;
  for (const entrada of ctx.sessionManager.getBranch()) {
    if (entrada.type !== "message") continue;
    const msg = entrada.message;
    if (msg.role === "toolResult" && msg.toolName === "ejecutar_tests" && msg.details) ultimo = msg.details;
  }
  ctx.ui.setStatus("tests", ultimo ? `tests: ${ultimo.pasan} pasan · ${ultimo.fallan} fallan` : undefined);
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => reconstruir(ctx));
  pi.on("session_tree", async (_event, ctx) => reconstruir(ctx));

  pi.registerTool({
    name: "ejecutar_tests",
    label: "Tests",
    description: "Ejecuta los tests del proyecto con node --test y devuelve cuántos pasan y cuántos fallan.",
    parameters: Type.Object({
      fichero: Type.Optional(Type.String({ description: "Fichero de test concreto, por ejemplo test/carrito.test.js. Omítelo para ejecutarlos todos." })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const args = ["--test", "--test-reporter=tap", ...(params.fichero ? [params.fichero] : [])];
      const salida = await run("node", args, { cwd: ctx.cwd, signal }).then(
        (r) => r.stdout,
        (e) => e.stdout ?? String(e),
      );
      const pasan = Number(salida.match(/# pass (\d+)/)?.[1] ?? 0);
      const fallan = Number(salida.match(/# fail (\d+)/)?.[1] ?? 0);
      if (pasan + fallan === 0) throw new Error(`No se ha ejecutado ningún test:\n${salida.slice(0, 500)}`);
      const fallos = salida.split("\n").filter((l) => l.startsWith("not ok")).join("\n");
      ctx.ui.setStatus("tests", `tests: ${pasan} pasan · ${fallan} fallan`);
      return {
        content: [{ type: "text", text: `${pasan} pasan, ${fallan} fallan.\n${fallos}` }],
        details: { pasan, fallan },
      };
    },
  });
}
