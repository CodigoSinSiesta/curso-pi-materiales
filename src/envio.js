// Coste de envío según el subtotal del pedido.

const COSTE_ENVIO = 4.95;
const LIMITE_GRATIS = 50;

/**
 * Devuelve los gastos de envío para un subtotal.
 * 4,95 € por defecto; gratis a partir de 40 €.
 */
export function gastosEnvio(subtotal) {
  if (typeof subtotal !== 'number' || !Number.isFinite(subtotal) || subtotal < 0) {
    throw new TypeError('El subtotal debe ser un número finito mayor o igual que 0');
  }
  return subtotal >= LIMITE_GRATIS ? 0 : COSTE_ENVIO;
}
