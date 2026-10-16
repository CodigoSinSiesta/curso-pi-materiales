// Pruebas de desglose. Los importes esperados están escritos a mano: nada se
// recalcula con las funciones de la tienda, para que el test pueda fallar.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { desglose } from '../src/desglose.js';

// Mochila 30 € + 3 libretas de 4 € = 42 €; con el cupón del 10 %, 37,80 €.
const mochilaYLibretas = [
  { nombre: 'Mochila', precio: 30, cantidad: 1 },
  { nombre: 'Libreta', precio: 4, cantidad: 3 },
];
const cupon10 = { porcentaje: 10 };
const silla = [{ nombre: 'Silla', precio: 45, cantidad: 1 }];

const casos = [
  {
    nombre: 'sin cupón, por encima del umbral (42 €, envío gratis)',
    lineas: mochilaYLibretas, cupon: undefined, tipoIVA: undefined,
    esperado: { base: 42, iva: 8.82, envio: 0, total: 50.82 },
  },
  {
    nombre: 'con cupón del 10 %, por debajo del umbral (37,80 €, envío 4,95 €)',
    lineas: mochilaYLibretas, cupon: cupon10, tipoIVA: undefined,
    esperado: { base: 37.8, iva: 7.94, envio: 4.95, total: 50.69 },
  },
  {
    nombre: 'justo en el umbral (40 €, envío gratis)',
    lineas: [{ nombre: 'Cesta', precio: 40, cantidad: 1 }], cupon: undefined, tipoIVA: undefined,
    esperado: { base: 40, iva: 8.4, envio: 0, total: 48.4 },
  },
  {
    nombre: 'sin cupón, por encima del umbral (45 €, envío gratis)',
    lineas: silla, cupon: undefined, tipoIVA: undefined,
    esperado: { base: 45, iva: 9.45, envio: 0, total: 54.45 },
  },
  {
    nombre: 'con cupón del 10 %, todavía por encima del umbral (40,50 €, envío gratis)',
    lineas: silla, cupon: cupon10, tipoIVA: undefined,
    esperado: { base: 40.5, iva: 8.51, envio: 0, total: 49.01 },
  },
  {
    nombre: 'con cupón del 10 % y un IVA del 10 % (37,80 €, envío 4,95 €)',
    lineas: mochilaYLibretas, cupon: cupon10, tipoIVA: 10,
    esperado: { base: 37.8, iva: 3.78, envio: 4.95, total: 46.53 },
  },
];

/** Redondea a céntimos cada importe del desglose para compararlo. */
const aCentimos = (d) => Object.fromEntries(
  ['base', 'iva', 'envio', 'total'].map((k) => [k, Math.round(d[k] * 100) / 100]),
);

for (const { nombre, lineas, cupon, tipoIVA, esperado } of casos) {
  test(`desglose ${nombre}`, () => {
    assert.deepEqual(aCentimos(desglose(lineas, cupon, tipoIVA)), esperado);
  });

  test(`desglose cuadra: base + IVA + envío = total ${nombre}`, () => {
    const d = desglose(lineas, cupon, tipoIVA);
    const centimos = (x) => Math.round(x * 100);
    assert.equal(centimos(d.base) + centimos(d.iva) + centimos(d.envio), centimos(d.total));
  });
}
