// Aceptación de ticket-003. Escrita antes del trabajo; quien implementa no la toca.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ticket, formatearEuros } from '../src/ticket.js';
import { totalConEnvio } from '../src/carrito.js';

// 42 € sin cupón; 37,80 € con el 10 %: por debajo del umbral de envío gratis (40 €, sin IVA).
const lineas = [{ nombre: 'Mochila', precio: 30, cantidad: 1 }, { nombre: 'Libreta', precio: 4, cantidad: 3 }];
const cupon = { porcentaje: 10 };

test('ticket-003: el total del ticket es el de totalConEnvio', () => {
  const esperado = formatearEuros(totalConEnvio(lineas, cupon));
  const texto = ticket(lineas, cupon);
  assert.ok(texto.includes(esperado), [
    `ERROR: el ticket termina en «${texto.trim().split('\n').at(-1)}» y el total de la tienda es ${esperado}.`,
    'POR QUÉ: el envío y su umbral se calculan sobre el total con cupón y sin IVA; el IVA solo va a los productos.',
    'CÓMO: usa totalConEnvio(lineas, cupon) de src/carrito.js y formatearEuros; no recalcules el total.',
  ].join('\n'));
});
