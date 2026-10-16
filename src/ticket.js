// Formateo de importes para el ticket.

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
