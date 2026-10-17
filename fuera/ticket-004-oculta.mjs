// Prueba oculta de ticket-004: vive fuera de la tienda y el agente no la ve.
// Uso: TIENDA=<carpeta de la tienda> node --test ~/csn/fuera/ticket-004-oculta.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

if (!process.env.TIENDA) throw new Error('Falta TIENDA=<carpeta de la tienda>.');
const { desglose } = await import(pathToFileURL(path.resolve(process.env.TIENDA, 'src/desglose.js')).href);
// Cada importe, a céntimos enteros y escrito con dos decimales: iguales si y solo si coinciden los céntimos.
const euros = (d) => Object.fromEntries(['base', 'iva', 'envio', 'total'].map((k) => [k, (Math.round(d[k] * 100) / 100).toFixed(2)]));

// Silla de 45 € con cupón del 20 %: 36,00 € sin IVA, por debajo del umbral de envío gratis. Calculado a mano.
test('oculta: silla de 45 € con cupón del 20 %', () => {
  const d = desglose([{ nombre: 'Silla', precio: 45, cantidad: 1 }], { porcentaje: 20 });
  assert.deepEqual(euros(d), { base: '36.00', iva: '7.56', envio: '4.95', total: '48.51' });
});
