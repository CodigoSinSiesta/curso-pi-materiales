// Formateo de importes para el ticket.
import { totalConEnvio, totalConCupon } from './carrito.js';
import { gastosEnvio } from './envio.js';

/**
 * Formatea un importe en euros con dos decimales, coma decimal y el símbolo €.
 * 4.95 → "4,95 €"; 10 → "10,00 €"; 1234.5 → "1234,50 €".
 */
export function formatearEuros(importe) {
  if (typeof importe !== 'number' || !Number.isFinite(importe) || importe < 0) {
    throw new TypeError('El importe debe ser un número finito mayor o igual que 0');
  }
  const redondeado = Math.round(importe * 100) / 100;
  return `${redondeado.toFixed(2).replace('.', ',')} €`;
}

/**
 * Devuelve la línea de ticket de un producto, con la forma
 * "<cantidad> x <nombre>  <precio> = <importe>", formateando los importes.
 */
export function lineaTicket({ nombre, precio, cantidad }) {
  return `${cantidad} x ${nombre}  ${formatearEuros(precio)} = ${formatearEuros(precio * cantidad)}`;
}

/**
 * Devuelve el ticket completo de un pedido: una línea por producto, una de
 * envío y una de total. El envío y el total se calculan reutilizando
 * gastosEnvio y totalConEnvio (umbral y IVA incluidos).
 */
export function ticket(lineas, cupon) {
  const productos = lineas.map(lineaTicket);
  const envio = gastosEnvio(totalConCupon(lineas, cupon));
  const total = totalConEnvio(lineas, cupon);
  return [
    ...productos,
    `Envío  ${formatearEuros(envio)}`,
    `Total  ${formatearEuros(total)}`,
  ].join('\n');
}
