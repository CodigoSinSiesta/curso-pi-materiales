import { test } from 'node:test';
import assert from 'node:assert/strict';
import { desglose } from '../src/desglose.js';
import { totalConCupon, totalConEnvio } from '../src/carrito.js';

const lineas = [
  { nombre: 'Mochila', precio: 30, cantidad: 1 },
  { nombre: 'Libreta', precio: 4, cantidad: 3 },
];
const cupon = { porcentaje: 10 };

test('desglose devuelve la base con cupón y el total de la tienda', () => {
  const d = desglose(lineas, cupon);
  assert.equal(d.base, totalConCupon(lineas, cupon));
  assert.equal(d.total, totalConEnvio(lineas, cupon));
});

test('desglose cuadra: base + IVA + envío = total', () => {
  const d = desglose(lineas, cupon);
  assert.equal(Math.round((d.base + d.iva + d.envio) * 100), Math.round(d.total * 100));
});

test('desglose sin cupón cuadra', () => {
  const d = desglose([{ nombre: 'Silla', precio: 45, cantidad: 1 }]);
  assert.equal(Math.round((d.base + d.iva + d.envio) * 100), Math.round(d.total * 100));
});
