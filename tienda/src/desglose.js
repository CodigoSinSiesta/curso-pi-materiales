// Desglose de un pedido: base imponible, IVA, envío y total, en euros.
import { aplicarIVA, totalConEnvio, totalConCupon } from './carrito.js';
import { gastosEnvio } from './envio.js';

/** Redondea a céntimos. */
const redondear = (importe) => Math.round(importe * 100) / 100;

/**
 * Devuelve { base, iva, envio, total } de un pedido, en euros redondeados a
 * céntimos:
 * - base: total con cupón sin IVA (totalConCupon);
 * - iva: aplicarIVA(base, tipoIVA) − base;
 * - envio: gastosEnvio(base) (el umbral de envío gratis se evalúa sin IVA);
 * - total: totalConEnvio(lineas, cupon, tipoIVA), de forma que
 *   base + iva + envio es igual a total.
 */
export function desglose(lineas, cupon, tipoIVA = 21) {
  const base = totalConCupon(lineas, cupon);
  const iva = redondear(aplicarIVA(base, tipoIVA) - base);
  const envio = gastosEnvio(base);
  const total = totalConEnvio(lineas, cupon, tipoIVA);
  return { base, iva, envio, total };
}
