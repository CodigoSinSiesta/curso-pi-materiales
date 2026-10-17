import { test } from 'node:test';
import assert from 'node:assert/strict';
import { gastosEnvio } from '../src/envio.js';

test('envío normal por debajo de 40 €', () => {
  assert.equal(gastosEnvio(10), 4.95);
  assert.equal(gastosEnvio(39.99), 4.95);
});

test('envío gratis a partir de 40 €', () => {
  assert.equal(gastosEnvio(40), 0);
  assert.equal(gastosEnvio(50), 0);
  assert.equal(gastosEnvio(120.5), 0);
});

test('gastosEnvio lanza TypeError con subtotales inválidos', () => {
  const invalidos = [NaN, Infinity, -Infinity, -1, -0.01, '10', null, undefined, {}, []];
  for (const valor of invalidos) {
    assert.throws(() => gastosEnvio(valor), TypeError);
  }
});
