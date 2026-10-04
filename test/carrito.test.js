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
  // 29 × 1,21 = 35,09 → +4,95 = 40,04
  assert.equal(totalConEnvio(lineas), 40.04);
  // 26,1 × 1,21 = 31,58 → +4,95 = 36,53
  assert.equal(totalConEnvio(lineas, { porcentaje: 10 }), 36.53);
});

test('totalConEnvio es gratis a partir de 40 € del total con IVA', () => {
  // 40 × 1,21 = 48,4 ≥ 40 → envío gratis
  assert.equal(totalConEnvio([{ precio: 40, cantidad: 1 }], { porcentaje: 0 }), 48.4);
  // 50 - 10 % = 45 → 45 × 1,21 = 54,45 ≥ 40 → envío gratis
  assert.equal(totalConEnvio([{ precio: 50, cantidad: 1 }], { porcentaje: 10 }), 54.45);
  // 30 × 1,21 = 36,3 < 40 → sigue pagando envío
  assert.equal(totalConEnvio([{ precio: 30, cantidad: 1 }], { porcentaje: 0 }), 41.25);
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
