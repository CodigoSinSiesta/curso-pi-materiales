// sdk-omp/resumen.ts sin modelo: la API que usa sigue ahí y la sesión de solo lectura se crea con esas herramientas.
// Uso: bun omp-sdk.ts <carpeta con node_modules/@oh-my-pi/pi-coding-agent> <carpeta de materiales>
// Escribe una línea por fallo: «ROTO<TAB>comando del curso<TAB>vídeo<TAB>detalle».
import { join } from "node:path";

const [carpeta, raiz] = process.argv.slice(2);
const roto = (detalle: string) => console.log(["ROTO", "sdk-omp/resumen.ts", "21", detalle].join("\t"));
const omp: any = await import(Bun.resolveSync("@oh-my-pi/pi-coding-agent", carpeta));

if (typeof omp.createAgentSession !== "function") roto("el paquete ya no exporta createAgentSession");
else if (typeof omp.SessionManager?.inMemory !== "function") roto("el paquete ya no exporta SessionManager.inMemory");
else {
  const cwd = join(raiz, "tienda");
  const { session } = await omp.createAgentSession({
    cwd,
    toolNames: ["read", "grep", "glob"],
    restrictToolNames: true,
    sessionManager: omp.SessionManager.inMemory(),
  });
  const activas = [...session.getActiveToolNames()].sort().join(",");
  if (activas !== "glob,grep,read") roto(`con toolNames read,grep,glob y restrictToolNames quedan activas: ${activas}`);
  else if (typeof session.getLastAssistantText !== "function") roto("la sesión ya no tiene getLastAssistantText()");
  else console.log(`ok    sdk-omp/resumen.ts: la sesión de solo lectura se crea sin modelo (${activas})`);
  await session.dispose();
}
