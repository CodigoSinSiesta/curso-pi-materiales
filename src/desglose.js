// Desglose del pedido: base sin IVA, IVA, envío y total.
import { subtotal, totalConCupon, totalConEnvio } from './carrito.js';
import { gastosEnvio } from './envio.js';

export function desglose(lineas, cupon, tipoIVA = 21) {
  const base = totalConCupon(lineas, cupon);
  const envio = gastosEnvio(subtotal(lineas));
  const total = totalConEnvio(lineas, cupon, tipoIVA);
  const iva = Math.round((total - base - envio) * 100) / 100;
  return { base, iva, envio, total };
}
