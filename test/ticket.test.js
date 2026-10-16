import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatearEuros } from '../src/ticket.js';

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
