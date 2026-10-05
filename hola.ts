import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("hola", {
    description: "Saluda a quien le digas",
    handler: async (nombre, ctx) => {
      ctx.ui.notify(`¡Hola, ${nombre || "mundo"}!`, "info");
    },
  });
}
