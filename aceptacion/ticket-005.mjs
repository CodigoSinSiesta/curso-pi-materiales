// Aceptación de ticket-005. Escrita antes del trabajo; quien implementa no la toca.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { totalConCupon, totalConEnvio } from '../src/carrito.js';
import { desglose } from '../src/desglose.js';
import { ticket } from '../src/ticket.js';

const cent = (x) => Math.round(x * 100); // los importes se comparan en céntimos enteros
const euros = (d) => Object.fromEntries(['base', 'iva', 'envio', 'total'].map((k) => [k, (cent(d[k]) / 100).toFixed(2)]));
const POR_QUE = 'POR QUÉ: un cupón { importe } resta esa cantidad una sola vez al subtotal, antes del IVA y del envío.';
const COMO = 'CÓMO: cambia solo totalConCupon en src/carrito.js; desglose, ticket y el envío ya lo usan.';

// 42 € en dos líneas; con 5 € de descuento, 37 €: por debajo del umbral de envío gratis (40 €, sin IVA).
const frontera = [{ nombre: 'Mochila', precio: 30, cantidad: 1 }, { nombre: 'Libreta', precio: 4, cantidad: 3 }];
// Silla de 45 € con 5 € de descuento: 40 € justos, en el umbral (envío gratis desde 40 €).
const umbral = [{ nombre: 'Silla', precio: 45, cantidad: 1 }];
const cinco = { importe: 5 };

test('ticket-005: el importe fijo se resta una sola vez al subtotal', () => {
  const real = totalConCupon(frontera, cinco);
  assert.equal(cent(real), 3700, [
    `ERROR: totalConCupon da ${real} y debería dar 37.00 (42 − 5).`, POR_QUE, COMO].join('\n'));
});

test('ticket-005: cada importe del desglose, a los dos lados del umbral', () => {
  for (const [nombre, lineas, esperado] of [
    ['frontera (37 € con cupón)', frontera, { base: '37.00', iva: '7.77', envio: '4.95', total: '49.72' }],
    ['umbral (40 € con cupón)', umbral, { base: '40.00', iva: '8.40', envio: '0.00', total: '48.40' }],
  ]) {
    const real = euros(desglose(lineas, cinco));
    const mal = Object.keys(esperado).filter((k) => real[k] !== esperado[k]);
    assert.deepEqual(real, esperado, [
      `ERROR: en el pedido ${nombre}, ${mal.map((k) => `${k} es ${real[k]} y debería ser ${esperado[k]}`).join('; ')}.`,
      POR_QUE, COMO].join('\n'));
    assert.equal(cent(totalConEnvio(lineas, cinco)), cent(Number(esperado.total)));
  }
});

test('ticket-005: el ticket cobra el importe con el cupón fijo', () => {
  const texto = ticket(frontera, cinco);
  assert.match(texto, /Envío {2}4,95 €\nTotal {2}49,72 €$/, [
    `ERROR: el ticket termina así:\n${texto.split('\n').slice(-2).join('\n')}\ny debería terminar en «Envío  4,95 €» y «Total  49,72 €».`,
    POR_QUE, COMO].join('\n'));
});

test('ticket-005: el cupón de porcentaje no cambia', () => {
  assert.equal(cent(totalConCupon(frontera, { porcentaje: 10 })), 3780, [
    'ERROR: el cupón { porcentaje: 10 } ya no da 37,80 € en el pedido de la frontera.',
    'POR QUÉ: la API de objeto del cupón se conserva tal cual.', 'CÓMO: añade el caso { importe } sin tocar el de porcentaje.'].join('\n'));
});

test('ticket-005: un importe negativo es un error', () => {
  assert.throws(() => totalConCupon(frontera, { importe: -5 }), TypeError, [
    'ERROR: totalConCupon acepta { importe: -5 }.', 'POR QUÉ: un cupón no puede subir el precio.',
    'CÓMO: lanza TypeError si el importe no es un número finito mayor que 0.'].join('\n'));
});
