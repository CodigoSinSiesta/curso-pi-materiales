// Comprobaciones de Pi como librería, sin modelo: herramientas, extensiones y la API que usa sdk/resumen.ts.
// Uso: node pi-sdk.mjs <carpeta del paquete @earendil-works/pi-coding-agent> <carpeta de materiales>
// Escribe una línea por fallo: «ROTO<TAB>comando del curso<TAB>vídeo<TAB>detalle».
import { pathToFileURL } from "node:url";
import { join } from "node:path";

const [paquete, raiz] = process.argv.slice(2);
const pi = await import(pathToFileURL(join(paquete, "dist/index.js")).href);
const roto = (comando, video, detalle) => console.log(["ROTO", comando, video, detalle].join("\t"));
const ok = (texto) => console.log(`ok    ${texto}`);

for (const nombre of ["createAgentSession", "SessionManager", "DefaultResourceLoader"]) {
  if (typeof pi[nombre] !== "function") roto("sdk/resumen.ts", "10", `el paquete ya no exporta ${nombre}`);
}
const { createAgentSession, SessionManager, DefaultResourceLoader } = pi;
const cwd = join(raiz, "tienda");

// Las siete herramientas integradas que nombran los scripts y las demos.
const SIETE = ["read", "bash", "edit", "write", "grep", "find", "ls"];
const DE_SERIE = ["read", "bash", "edit", "write"];
{
  const { session } = await createAgentSession({ cwd, sessionManager: SessionManager.inMemory(cwd) });
  const todas = session.getAllTools().map((t) => t.name);
  const faltan = SIETE.filter((t) => !todas.includes(t));
  if (faltan.length) roto("pi --tools read,grep,find,ls (y medir.sh, prefijo.sh)", "05, 10, 22",
    `Pi ya no tiene: ${faltan.join(", ")}. Pi ignora en silencio las herramientas que no existen`);
  else ok(`Pi tiene las siete herramientas integradas: ${SIETE.join(", ")}`);
  const activas = session.getActiveToolNames();
  if (activas.join(",") !== DE_SERIE.join(",")) roto("pi (las cuatro herramientas de serie)", "03, 22",
    `las herramientas activas por defecto son ${activas.join(", ")}, no ${DE_SERIE.join(", ")}`);
  else ok(`las de serie siguen siendo ${DE_SERIE.join(", ")}`);
  session.dispose();
}

// sdk/resumen.ts: sesión en memoria con herramientas de lectura.
{
  const { session } = await createAgentSession({
    cwd, tools: ["read", "grep", "find", "ls"], sessionManager: SessionManager.inMemory(cwd),
  });
  const activas = session.getActiveToolNames().sort().join(",");
  if (activas !== "find,grep,ls,read") roto("sdk/resumen.ts", "10", `con tools read,grep,find,ls quedan activas: ${activas}`);
  else if (typeof session.getLastAssistantText !== "function") roto("sdk/resumen.ts", "10", "la sesión ya no tiene getLastAssistantText()");
  else ok("sdk/resumen.ts: la sesión de solo lectura se crea sin modelo");
  session.dispose();
}

// La herramienta de extensiones/tests.ts.
{
  const resourceLoader = new DefaultResourceLoader({
    cwd, agentDir: join(process.env.HOME, ".pi", "agent"),
    additionalExtensionPaths: [join(raiz, "extensiones", "tests.ts")],
  });
  await resourceLoader.reload();
  const { session } = await createAgentSession({ cwd, resourceLoader, sessionManager: SessionManager.inMemory(cwd) });
  if (!session.getAllTools().some((t) => t.name === "ejecutar_tests"))
    roto("pi -e extensiones/tests.ts", "08", "la extensión carga, pero no registra la herramienta ejecutar_tests");
  else ok("extensiones/tests.ts registra ejecutar_tests");
  session.dispose();
}
