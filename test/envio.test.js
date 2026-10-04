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
