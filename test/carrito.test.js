import { test } from 'node:test';
import assert from 'node:assert/strict';
import { subtotal, totalConCupon, totalConEnvio, aplicarIVA } from '../src/carrito.js';

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

test('totalConEnvio suma el envío cuando no llega al umbral', () => {
  assert.equal(totalConEnvio(lineas), 33.95); // 29 + 4.95
  assert.equal(totalConEnvio(lineas, { porcentaje: 10 }), 31.05); // 26.1 + 4.95
});

test('totalConEnvio es gratis a partir de 40 € sobre el total descontado', () => {
  assert.equal(totalConEnvio([{ precio: 40, cantidad: 1 }], { porcentaje: 0 }), 40);
  // 50 - 10 % = 45 ≥ 40, aunque el subtotal original es 50
  assert.equal(totalConEnvio([{ precio: 50, cantidad: 1 }], { porcentaje: 10 }), 45);
});

test('aplicarIVA usa el 21 % por defecto', () => {
  assert.equal(aplicarIVA(100), 121);
});

test('aplicarIVA acepta un tipo distinto', () => {
  assert.equal(aplicarIVA(100, 10), 110);
});

test('aplicarIVA redondea a céntimos', () => {
  assert.equal(aplicarIVA(29.99), 36.29); // 29.99 × 1.21 = 36.2879
  assert.equal(aplicarIVA(0.1), 0.12); // 0.1 × 1.21 = 0.121 → 0.12
});
