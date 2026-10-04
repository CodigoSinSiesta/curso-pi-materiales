// Coste de envío según el subtotal del pedido.

const COSTE_ENVIO = 4.95;
const LIMITE_GRATIS = 40;

/**
 * Devuelve los gastos de envío para un subtotal.
 * 4,95 € por defecto; gratis a partir de 40 €.
 */
export function gastosEnvio(subtotal) {
  return subtotal >= LIMITE_GRATIS ? 0 : COSTE_ENVIO;
}
