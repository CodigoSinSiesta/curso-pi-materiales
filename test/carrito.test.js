import { test } from 'node:test';
import assert from 'node:assert/strict';
import { subtotal, totalConCupon } from '../src/carrito.js';

const lineas = [
  { nombre: 'Taza', precio: 8.5, cantidad: 2 },
  { nombre: 'Libreta', precio: 4, cantidad: 3 },
];

test('subtotal suma precio por cantidad', () => {
  assert.equal(subtotal(lineas), 29);
});

test('sin cupón el total es el subtotal', () => {
  assert.equal(totalConCupon(lineas), 29);
});

test('un cupón del 10 % descuenta una sola vez', () => {
  assert.equal(totalConCupon(lineas, { porcentaje: 10 }), 26.1);
});
