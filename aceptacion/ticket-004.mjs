// Aceptación de ticket-004. Escrita antes del trabajo; quien implementa no la toca.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { desglose } from '../src/desglose.js';
import { totalConEnvio } from '../src/carrito.js';

// 42 € sin cupón; 37,80 € con el 10 %: por debajo del umbral de envío gratis (40 €, sin IVA).
const lineas = [{ nombre: 'Mochila', precio: 30, cantidad: 1 }, { nombre: 'Libreta', precio: 4, cantidad: 3 }];
const cupon = { porcentaje: 10 };
const cent = (x) => Math.round(x * 100); // los importes se comparan en céntimos enteros

test('ticket-004: el total del desglose es el de totalConEnvio', () => {
  const d = desglose(lineas, cupon);
  assert.equal(cent(d.total), cent(totalConEnvio(lineas, cupon)), [
    `ERROR: el desglose da un total de ${d.total} y el de la tienda es ${totalConEnvio(lineas, cupon)}.`,
    'POR QUÉ: el envío y su umbral se calculan sobre el total con cupón y sin IVA; el IVA solo va a los productos.',
    'CÓMO: usa totalConEnvio(lineas, cupon) de src/carrito.js; no recalcules el total.',
  ].join('\n'));
});

test('ticket-004: base + IVA + envío es igual al total', () => {
  const d = desglose(lineas, cupon);
  assert.equal(cent(d.base) + cent(d.iva) + cent(d.envio), cent(d.total), [
    `ERROR: ${d.base} + ${d.iva} + ${d.envio} no suma ${d.total}.`,
    'POR QUÉ: el desglose tiene que cuadrar con el total, céntimo a céntimo.',
    'CÓMO: redondea cada importe a céntimos con Math.round(x * 100) / 100.',
  ].join('\n'));
});
