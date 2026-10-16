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

// Cada importe, escrito a mano: el pedido de la frontera y uno por encima del umbral (silla de 45 € sin cupón).
const pedidos = [
  { nombre: 'frontera (37,80 € con cupón)', lineas, cupon, esperado: { base: 37.8, iva: 7.94, envio: 4.95, total: 50.69 } },
  { nombre: 'por encima del umbral (45 € sin cupón)', lineas: [{ nombre: 'Silla', precio: 45, cantidad: 1 }],
    cupon: undefined, esperado: { base: 45, iva: 9.45, envio: 0, total: 54.45 } },
];

const euros = (d) => Object.fromEntries(['base', 'iva', 'envio', 'total'].map((k) => [k, (cent(d[k]) / 100).toFixed(2)]));

for (const p of pedidos) {
  test(`ticket-004: cada importe del pedido ${p.nombre}`, () => {
    const real = euros(desglose(p.lineas, p.cupon)), esperado = euros(p.esperado);
    const mal = Object.keys(esperado).filter((k) => real[k] !== esperado[k]);
    assert.deepEqual(real, esperado, [
      `ERROR: en el pedido ${p.nombre}, ${mal.map((k) => `${k} es ${real[k]} y debería ser ${esperado[k]}`).join('; ')}.`,
      'POR QUÉ: base = total con cupón sin IVA; IVA = aplicarIVA(base) − base; envío = gastosEnvio(base).',
      'CÓMO: calcula cada importe con las funciones de src/carrito.js y src/envio.js; no lo saques por diferencia.',
    ].join('\n'));
  });
}
