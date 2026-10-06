import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { relative } from "node:path";

// Herramientas que solo leen: pasan sin preguntar.
const LECTURA = ["read", "grep", "find", "ls", "ejecutar_tests"];
// Comandos de bash que tampoco cambian nada.
const SEGURO = /^(cd|ls|cat|head|tail|wc|grep|echo|git (status|log|diff)|node --test|npm test)\b/;

// Rutas que nunca se tocan, ni preguntando.
const PROTEGIDAS = ["AGENTS.md", ".git/"];

// Un comando es seguro si cada trozo (separado por &&, ; o |) lo es y no redirige nada.
function bashSeguro(comando: string) {
  comando = comando.replace(/2>(&1|\/dev\/null)/g, ""); // estas redirecciones no escriben nada
  if (/[<>`]|\$\(/.test(comando)) return false;
  return comando.split(/&&|\|\||;|\|/).every((trozo) => SEGURO.test(trozo.trim()));
}

export default function (pi: ExtensionAPI) {
  const siempre = new Set<string>(); // lo aprobado con «Permitir siempre» en esta rama
  let aprobadas = 0;
  let bloqueadas = 0;

  // Rehace el estado a partir de las decisiones guardadas en la rama activa.
  function reconstruir(ctx: ExtensionContext) {
    siempre.clear();
    aprobadas = 0;
    bloqueadas = 0;
    for (const entrada of ctx.sessionManager.getBranch()) {
      if (entrada.type !== "custom" || entrada.customType !== "permisos") continue;
      const { que, decision } = entrada.data as { que: string; decision: string };
      if (decision === "bloquear") bloqueadas++;
      else aprobadas++;
      if (decision === "siempre") siempre.add(que);
    }
    ctx.ui.setStatus("permisos", `permisos: ${aprobadas} aprobadas · ${bloqueadas} bloqueadas`);
  }
  pi.on("session_start", async (_event, ctx) => reconstruir(ctx));
  pi.on("session_tree", async (_event, ctx) => reconstruir(ctx));

  pi.on("tool_call", async (event, ctx) => {
    if (LECTURA.includes(event.toolName)) return;

    const ruta = relative(ctx.cwd, String(event.input.path ?? ""));
    if ((event.toolName === "write" || event.toolName === "edit") && PROTEGIDAS.some((p) => ruta.startsWith(p))) {
      ctx.ui.notify(`Ruta protegida: ${ruta}`, "warning");
      return { block: true, reason: `${ruta} está protegido y no se puede modificar` };
    }

    const que =
      event.toolName === "bash" ? String(event.input.command) : `${event.toolName} ${ruta}`;
    if (event.toolName === "bash" && bashSeguro(que)) return;
    if (siempre.has(que)) return;

    // Sin interfaz (pi -p, JSON) no hay a quién preguntar: se bloquea.
    if (!ctx.hasUI) return { block: true, reason: "Sin interfaz para aprobar la acción" };

    const opcion = await ctx.ui.select(`Pi quiere ejecutar:\n\n  ${que}\n`, [
      "Permitir",
      "Permitir siempre en esta rama",
      "Bloquear",
    ]);
    const decision = opcion === "Permitir" ? "una" : opcion === "Permitir siempre en esta rama" ? "siempre" : "bloquear";
    pi.appendEntry("permisos", { que, decision }); // la decisión queda guardada en la sesión
    if (decision === "siempre") siempre.add(que);
    if (decision === "bloquear") {
      bloqueadas++;
    } else {
      aprobadas++;
    }
    ctx.ui.setStatus("permisos", `permisos: ${aprobadas} aprobadas · ${bloqueadas} bloqueadas`);
    if (decision === "bloquear") return { block: true, reason: "El usuario lo ha bloqueado" };
  });
}
