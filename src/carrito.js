// Cálculo del total de un carrito con un cupón de descuento opcional.
import { gastosEnvio } from './envio.js';

/**
 * Devuelve el importe con IVA aplicado (importe + IVA), redondeado a céntimos.
 * El tipo es un porcentaje; por defecto el 21 %.
 */
export function aplicarIVA(importe, tipo = 21) {
  return Math.round(importe * (1 + tipo / 100) * 100) / 100;
}

/** Suma precio × cantidad de cada línea. */
export function subtotal(lineas) {
  return lineas.reduce((acc, l) => acc + l.precio * l.cantidad, 0);
}

/**
 * Aplica un cupón porcentual al subtotal y redondea a céntimos.
 * Un cupón { porcentaje: 10 } descuenta el 10 % una sola vez sobre el subtotal.
 */
export function totalConCupon(lineas, cupon) {
  let total = 0;
  for (const l of lineas) {
    const linea = l.precio * l.cantidad;
    total += cupon ? linea - linea * (cupon.porcentaje / 100) : linea;
  }
  return Math.round(total * 100) / 100;
}

/**
 * Total final del pedido: total con cupón + gastos de envío.
 * El umbral de envío gratis se aplica sobre el total ya descontado.
 */
export function totalConEnvio(lineas, cupon) {
  const totalCupon = totalConCupon(lineas, cupon);
  return Math.round((totalCupon + gastosEnvio(totalCupon)) * 100) / 100;
}
