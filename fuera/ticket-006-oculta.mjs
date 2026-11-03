// Prueba oculta de ticket-006: vive fuera de la tienda y el agente no la ve.
// Uso: TIENDA=<carpeta de la tienda> node --test ~/csn/fuera/ticket-006-oculta.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

if (!process.env.TIENDA) throw new Error('Falta TIENDA=<carpeta de la tienda>.');
const src = (f) => import(pathToFileURL(path.resolve(process.env.TIENDA, 'src', f)).href);
const { totalConCupon } = await src('carrito.js');
const { desglose } = await src('desglose.js');
const silla = [{ nombre: 'Silla', precio: 45, cantidad: 1 }];

// Otro pedido que el de la aceptación: la silla de 45 €. Sin valor o con NaN, el cupón es un error.
test('oculta: la silla con un importe sin valor o NaN', () => {
  for (const importe of [undefined, NaN]) assert.throws(() => totalConCupon(silla, { importe }), TypeError, `importe: ${importe}`);
});

// Calculado a mano: 45 − 10 = 35 € sin IVA, por debajo del umbral. Lo que ya funcionaba sigue igual.
test('oculta: la silla con un cupón de 10 € sigue costando 47,30 €', () => {
  assert.equal((Math.round(desglose(silla, { importe: 10 }).total * 100) / 100).toFixed(2), '47.30');
});
