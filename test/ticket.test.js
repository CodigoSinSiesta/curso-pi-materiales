import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatearEuros, lineaTicket, ticket } from '../src/ticket.js';

test('formatearEuros usa dos decimales, coma y el símbolo del euro', () => {
  assert.equal(formatearEuros(4.95), '4,95 €');
  assert.equal(formatearEuros(10), '10,00 €');
  assert.equal(formatearEuros(0), '0,00 €');
  assert.equal(formatearEuros(1234.5), '1234,50 €');
});

test('formatearEuros redondea a céntimos', () => {
  assert.equal(formatearEuros(0.1 + 0.2), '0,30 €'); // 0.30000000000000004
  assert.equal(formatearEuros(2.005), '2,01 €');
});

test('formatearEuros lanza TypeError con importes inválidos', () => {
  const invalidos = [NaN, Infinity, -Infinity, -1, -0.01, '10', null, undefined, {}, []];
  for (const valor of invalidos) {
    assert.throws(() => formatearEuros(valor), TypeError);
  }
});

test('lineaTicket formatea varias unidades con importes en euros', () => {
  assert.equal(
    lineaTicket({ nombre: 'Taza', precio: 4.5, cantidad: 2 }),
    '2 x Taza  4,50 € = 9,00 €'
  );
});

test('lineaTicket con una sola unidad', () => {
  assert.equal(
    lineaTicket({ nombre: 'Lápiz', precio: 1.25, cantidad: 1 }),
    '1 x Lápiz  1,25 € = 1,25 €'
  );
});

test('lineaTicket redondea el importe a céntimos', () => {
  assert.equal(
    lineaTicket({ nombre: 'Bolígrafo', precio: 0.1, cantidad: 3 }),
    '3 x Bolígrafo  0,10 € = 0,30 €'
  );
});

test('ticket por debajo de 40 € cobra el envío', () => {
  // 20 € → envío 4,95 €; 20 × 1,21 = 24,20 + 4,95 = 29,15
  assert.equal(
    ticket([{ nombre: 'Taza', precio: 10, cantidad: 2 }]),
    '2 x Taza  10,00 € = 20,00 €\nEnvío: 4,95 €\nTotal: 29,15 €'
  );
});

test('ticket por debajo de 40 € con cupón', () => {
  // 20 € - 10 % = 18; 18 × 1,21 = 21,78 + 4,95 = 26,73
  assert.equal(
    ticket([{ nombre: 'Taza', precio: 10, cantidad: 2 }], { porcentaje: 10 }),
    '2 x Taza  10,00 € = 20,00 €\nEnvío: 4,95 €\nTotal: 26,73 €'
  );
});

test('ticket calcula el envío sobre el total con cupón, no sobre el subtotal', () => {
  // 42 € - 10 % = 37,80 € (por debajo de 40 €): envío 4,95 €; 37,80 × 1,21 = 45,74 + 4,95 = 50,69
  assert.equal(
    ticket(
      [{ nombre: 'Mochila', precio: 30, cantidad: 1 }, { nombre: 'Libreta', precio: 4, cantidad: 3 }],
      { porcentaje: 10 }
    ),
    '1 x Mochila  30,00 € = 30,00 €\n3 x Libreta  4,00 € = 12,00 €\nEnvío: 4,95 €\nTotal: 50,69 €'
  );
});

test('ticket por encima de 40 € con cupón: envío gratis', () => {
  // 60 € - 10 % = 54; 54 × 1,21 = 65,34; envío 0
  assert.equal(
    ticket([{ nombre: 'Lámpara', precio: 60, cantidad: 1 }], { porcentaje: 10 }),
    '1 x Lámpara  60,00 € = 60,00 €\nEnvío: 0,00 €\nTotal: 65,34 €'
  );
});
