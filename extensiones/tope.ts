// tope.ts: un tope de coste para Pi, que no lo trae. Suma el coste de cada respuesta del modelo y, cuando pasa de
// PI_TOPE_USD (0,10 $ si no se dice otra cosa), aborta el turno. Sin imports del paquete: se carga con `pi -e`.
// Uso: PI_TOPE_USD=0.05 pi -p -e ~/csn/extensiones/tope.ts "…"
export default function (pi: any) {
  const tope = Number(process.env.PI_TOPE_USD ?? "0.10");
  let gastado = 0;

  pi.on("session_start", async (_event: any, ctx: any) => {
    if (ctx.hasUI) ctx.ui.notify(`tope: activo (${tope} $)`, "info");
  });

  pi.on("message_end", async (event: any, ctx: any) => {
    if (event.message?.role !== "assistant") return;
    gastado += event.message.usage?.cost?.total ?? 0;
    if (gastado < tope) return;
    console.error(`tope: ${gastado.toFixed(4)} $ de ${tope} $; se para`);
    ctx.abort();
  });
}
