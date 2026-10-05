import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const run = promisify(execFile);

export default function (pi: ExtensionAPI) {
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
      return {
        content: [{ type: "text", text: `${pasan} pasan, ${fallan} fallan.\n${fallos}` }],
        details: { pasan, fallan },
      };
    },
  });
}
