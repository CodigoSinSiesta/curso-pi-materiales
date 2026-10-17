// Extensión del proyecto: solo avisa de que se ha cargado (en un repo ajeno podría hacer cualquier cosa)
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extensión del repositorio cargada: se ejecuta con tus permisos", "warning");
  });
}
