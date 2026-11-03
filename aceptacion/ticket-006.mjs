// Aceptación de ticket-006. Escrita antes del trabajo; quien implementa no la toca.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { totalConCupon } from '../src/carrito.js';

const cent = (x) => Math.round(x * 100); // los importes se comparan en céntimos enteros
const POR_QUE = 'POR QUÉ: si el cupón trae la propiedad importe, su valor tiene que ser un número finito mayor que 0, aunque venga vacío.';
const COMO = 'CÓMO: en totalConCupon (src/carrito.js), decide por si la propiedad importe está, no por si su valor es undefined.';

// 42 € en dos líneas, el pedido de la frontera del 005.
const frontera = [{ nombre: 'Mochila', precio: 30, cantidad: 1 }, { nombre: 'Libreta', precio: 4, cantidad: 3 }];

test('ticket-006: un importe presente pero sin valor es un error', () => {
  for (const importe of [undefined, null]) {
    assert.throws(() => totalConCupon(frontera, { importe }), TypeError, [
      `ERROR: totalConCupon acepta { importe: ${importe} } y devuelve ${(() => { try { return totalConCupon(frontera, { importe }); } catch { return 'un error que no es TypeError'; } })()}.`,
      POR_QUE, COMO].join('\n'));
  }
});

test('ticket-006: el cupón de porcentaje no cambia', () => {
  assert.equal(cent(totalConCupon(frontera, { porcentaje: 10 })), 3780, [
    'ERROR: el cupón { porcentaje: 10 } ya no da 37,80 € en el pedido de la frontera.',
    'POR QUÉ: la API de objeto del cupón se conserva tal cual.', 'CÓMO: arregla solo el caso { importe }.'].join('\n'));
});
