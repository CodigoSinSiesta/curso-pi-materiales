// puerta.ts: el paso a «pasa» y el commit los decide ./verificar.sh, no el agente.
// Sin imports del paquete: se carga con `pi -e` y con `omp --hook`.
import { readFile, writeFile } from "node:fs/promises";

const PROTEGIDAS = ["rubricas/", "aceptacion/", "verificar.sh"];
const LISTA = "funcionalidades.json";
const antes = new Map<string, string>();
const rutas = (i: any) => [i?.path, ...(i?.paths ?? [])].filter(Boolean).map(String);
const enPasa = (t: string) => { try { return new Set<string>(JSON.parse(t).funcionalidades
  .filter((f: any) => f.estado === "pasa").map((f: any) => f.id)); } catch { return new Set<string>(); } };

export default function (pi: any) {
  const verificar = (ids: string[], cwd: string) => pi.exec("./verificar.sh", ids, { cwd, timeout: 120_000 });
  const falla = (r: any) => r.code !== 0 || r.killed; // Pi devuelve code 0 si lo mata el timeout
  const motivo = (r: any) => `${(r.stdout + r.stderr).slice(-3000)}\nArregla el código, no la verificación.`;

  pi.on("session_start", async (_event: any, ctx: any) => {
    if (ctx.hasUI) ctx.ui.notify("puerta: activa (pasa y commit pasan por ./verificar.sh)", "info");
  });

  pi.on("tool_call", async (event: any, ctx: any) => {
    if (event.toolName === "edit" || event.toolName === "write") {
      const r = rutas(event.input);
      if (r.some((p) => PROTEGIDAS.some((x) => p.includes(x)))) return { block: true, reason:
        "ERROR: ruta protegida.\nPOR QUÉ: la rúbrica, la aceptación y verificar.sh no los cambia quien hace el trabajo.\n" +
        "CÓMO: si crees que la verificación está mal, explícalo y para." };
      if (r.some((p) => p.endsWith(LISTA)))
        antes.set(event.toolCallId, await readFile(`${ctx.cwd}/${LISTA}`, "utf8").catch(() => ""));
    }
    if (event.toolName === "bash" && /\bgit\s+commit\b/.test(String(event.input?.command ?? ""))) {
      const r = await verificar([], ctx.cwd); // sin id: solo lo que ya está en pasa (se puede commitear trabajo en curso)
      if (falla(r)) return { block: true, reason: motivo(r) };
    }
  });

  pi.on("tool_result", async (event: any, ctx: any) => {
    const previo = antes.get(event.toolCallId);
    if (previo === undefined) return;
    antes.delete(event.toolCallId);
    const nuevas = [...enPasa(await readFile(`${ctx.cwd}/${LISTA}`, "utf8"))].filter((id) => !enPasa(previo).has(id));
    if (!nuevas.length) return;
    const r = await verificar(nuevas, ctx.cwd);
    if (!falla(r)) return;
    await writeFile(`${ctx.cwd}/${LISTA}`, previo); // se deshace el marcado
    if (ctx.hasUI) ctx.ui.notify(`puerta: ${nuevas.join(", ")} no pasa ./verificar.sh`, "warning");
    return { isError: true, content: [{ type: "text", text: motivo(r) }] };
  });
}
