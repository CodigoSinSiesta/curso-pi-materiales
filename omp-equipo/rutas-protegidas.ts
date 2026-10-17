// Rutas protegidas: el bloque de rutas del permisos.ts del vídeo 08, como hook de oh my pi.
const EDITAN = ["edit", "write", "ast_edit"];
const DATOS = `${process.env.HOME}/csn/datos/`;

export default function (pi) {
  pi.on("tool_call", async (event, ctx) => {
    if (!EDITAN.includes(event.toolName)) return;
    const rutas = event.input.paths ?? [event.input.path];
    for (const ruta of rutas) {
      if (!ruta) continue;
      const rel = String(ruta).replace(`${ctx.cwd}/`, "").replace(/^\.\//, "");
      if (rel === "AGENTS.md" || rel.startsWith(".git/") || rel.startsWith(".omp/") || String(ruta).startsWith(DATOS)) {
        if (ctx.hasUI) ctx.ui.notify(`Ruta protegida: ${rel}`, "warning");
        return { block: true, reason: `${rel} está protegido y no se puede modificar` };
      }
    }
  });
}
