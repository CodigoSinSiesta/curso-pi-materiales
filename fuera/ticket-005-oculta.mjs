// Prueba oculta de ticket-005: vive fuera de la tienda y el agente no la ve.
// Uso: TIENDA=<carpeta de la tienda> node --test ~/csn/fuera/ticket-005-oculta.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

if (!process.env.TIENDA) throw new Error('Falta TIENDA=<carpeta de la tienda>.');
const src = (f) => import(pathToFileURL(path.resolve(process.env.TIENDA, 'src', f)).href);
const { desglose } = await src('desglose.js');
const euros = (d) => Object.fromEntries(['base', 'iva', 'envio', 'total'].map((k) => [k, (Math.round(d[k] * 100) / 100).toFixed(2)]));

// Calculado a mano. Silla de 45 € con un cupón de 10 €: 35 € sin IVA, por debajo del umbral.
test('oculta: silla de 45 € con un cupón de 10 €', () => {
  assert.deepEqual(euros(desglose([{ nombre: 'Silla', precio: 45, cantidad: 1 }], { importe: 10 })),
    { base: '35.00', iva: '7.35', envio: '4.95', total: '47.30' });
});

// Tres libretas de 4 € con un cupón de 15 €: el descuento no baja de 0; el envío se cobra igual.
test('oculta: un cupón mayor que el pedido deja la base en 0', () => {
  assert.deepEqual(euros(desglose([{ nombre: 'Libreta', precio: 4, cantidad: 3 }], { importe: 15 })),
    { base: '0.00', iva: '0.00', envio: '4.95', total: '4.95' });
});
