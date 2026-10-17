import { test } from 'node:test';
import assert from 'node:assert/strict';
import { subtotal, contarUnidades, totalConCupon, totalConEnvio, aplicarIVA } from '../src/carrito.js';

const lineas = [
  { nombre: 'Taza', precio: 8.5, cantidad: 2 },
  { nombre: 'Libreta', precio: 4, cantidad: 3 },
];

test('subtotal suma precio por cantidad', () => {
  assert.equal(subtotal(lineas), 29);
});

test('contarUnidades suma las cantidades de las líneas', () => {
  assert.equal(contarUnidades(lineas), 5); // 2 + 3
});

test('contarUnidades devuelve 0 con un carrito vacío', () => {
  assert.equal(contarUnidades([]), 0);
});

test('sin cupón el total es el subtotal', () => {
  assert.equal(totalConCupon(lineas), 29);
});

test('un cupón del 10 % descuenta una sola vez', () => {
  assert.equal(totalConCupon(lineas, { porcentaje: 10 }), 26.1);
});

test('totalConEnvio aplica el IVA a los productos y suma el envío', () => {
  // 29 × 1.21 = 35.09; envío calculado sin IVA: 29 < 40 → 4.95
  assert.equal(totalConEnvio(lineas), 40.04);
  // 29 - 10 % = 26.1; 26.1 × 1.21 = 31.581 → 31.58; + 4.95
  assert.equal(totalConEnvio(lineas, { porcentaje: 10 }), 36.53);
});

test('totalConEnvio es gratis a partir de 40 € sobre el total sin IVA', () => {
  // 40 sin IVA ≥ 40 → envío gratis; 40 × 1.21 = 48.4
  assert.equal(totalConEnvio([{ precio: 40, cantidad: 1 }], { porcentaje: 0 }), 48.4);
  // 50 - 10 % = 45 ≥ 40 → envío gratis; 45 × 1.21 = 54.45
  assert.equal(totalConEnvio([{ precio: 50, cantidad: 1 }], { porcentaje: 10 }), 54.45);
});

test('el envío se decide con el total SIN IVA, no con el total con IVA', () => {
  // 35 sin IVA < 40 → paga envío; 35 × 1.21 = 42.35 + 4.95
  assert.equal(totalConEnvio([{ precio: 35, cantidad: 1 }]), 47.3);
});

test('totalConEnvio acepta un tipo de IVA distinto', () => {
  // 40 sin IVA ≥ 40 → envío gratis; 40 × 1.10 = 44
  assert.equal(totalConEnvio([{ precio: 40, cantidad: 1 }], undefined, 10), 44);
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

test('un cupón de importe fijo se resta una sola vez al subtotal', () => {
  // 30 + 4 × 3 = 42; 42 − 5 = 37 (no 5 por cada línea)
  const dosLineas = [
    { nombre: 'Mochila', precio: 30, cantidad: 1 },
    { nombre: 'Libreta', precio: 4, cantidad: 3 },
  ];
  assert.equal(totalConCupon(dosLineas, { importe: 5 }), 37);
});

test('totalConEnvio resta el importe fijo antes del IVA y del envío', () => {
  // 29 − 5 = 24; 24 × 1.21 = 29.04; 24 < 40 → envío 4.95 → 33.99
  assert.equal(totalConEnvio(lineas, { importe: 5 }), 33.99);
});

test('un cupón de importe fijo que deja el total en el umbral no paga envío', () => {
  // 45 − 5 = 40 ≥ 40 → envío 0; 40 × 1.21 = 48.4
  assert.equal(totalConEnvio([{ precio: 45, cantidad: 1 }], { importe: 5 }), 48.4);
});

test('un cupón mayor que el pedido deja el total en 0', () => {
  // 42 − 50 = −8 → 0
  assert.equal(totalConCupon([{ precio: 42, cantidad: 1 }], { importe: 50 }), 0);
});

test('un importe de cupón no válido lanza TypeError', () => {
  for (const importe of [0, -5, NaN, Infinity, '5', null, {}]) {
    assert.throws(() => totalConCupon(lineas, { importe }), TypeError, `importe: ${String(importe)}`);
  }
});
