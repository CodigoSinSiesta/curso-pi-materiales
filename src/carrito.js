// Cálculo del total de un carrito con un cupón de descuento opcional.

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
