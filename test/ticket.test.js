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

test('ticket por debajo del umbral con cupón incluye el envío', () => {
  const lineas = [
    { nombre: 'Mochila', precio: 30, cantidad: 1 },
    { nombre: 'Libreta', precio: 4, cantidad: 3 },
  ];
  const cupon = { porcentaje: 10 };
  assert.equal(
    ticket(lineas, cupon),
    [
      '1 x Mochila  30,00 € = 30,00 €',
      '3 x Libreta  4,00 € = 12,00 €',
      'Envío  4,95 €',
      'Total  50,69 €',
    ].join('\n')
  );
});

test('ticket por encima del umbral sin cupón es gratis de envío', () => {
  const lineas = [{ nombre: 'Silla', precio: 45, cantidad: 1 }];
  assert.equal(
    ticket(lineas),
    [
      '1 x Silla  45,00 € = 45,00 €',
      'Envío  0,00 €',
      'Total  54,45 €',
    ].join('\n')
  );
});

test('ticket por encima del umbral con cupón es gratis de envío', () => {
  const lineas = [{ nombre: 'Silla', precio: 50, cantidad: 1 }];
  const cupon = { porcentaje: 10 };
  assert.equal(
    ticket(lineas, cupon),
    [
      '1 x Silla  50,00 € = 50,00 €',
      'Envío  0,00 €',
      'Total  54,45 €',
    ].join('\n')
  );
});
