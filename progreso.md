# Progreso

Registro de sesiones de la tienda, para cualquier agente. Se lee al empezar y se actualiza al terminar, porque así lo
pide `AGENTS.md`; ningún agente lo actualiza solo.

## Estado verificado

- Raíz del repositorio: `~/csn/tienda`, rama `andamiaje`
- Arranque estándar: `./init.sh`
- Verificación estándar: `npm test`
- Funcionalidad en curso: ninguna; `ticket-004` en `pasa` y el resto también en `pasa`.
- Bloqueo actual: ninguno

## Registro de sesiones

<!-- Una entrada por sesión: fecha, agente, objetivo, completado, verificación ejecutada, evidencia, commits,
     riesgos y siguiente paso. -->

### 2026-10-16 · Pi · ticket-001 (Formatear euros)

- Objetivo: implementar `formatearEuros(importe)` en `src/ticket.js`.
- Completado: función con dos decimales, coma decimal y símbolo €; valida el importe (TypeError si no es un número
  finito ≥ 0) y redondea a céntimos.
- Verificación ejecutada: `node --test test/ticket.test.js` → 3 pass / 0 fail; `npm test` → 18 pass / 0 fail.
- Evidencia: `4.95 → "4,95 €"`, `10 → "10,00 €"`, `0 → "0,00 €"`, `1234.5 → "1234,50 €"`; casos inválidos
  (`NaN`, `Infinity`, negativos, `'10'`, `null`, `undefined`, `{}`, `[]`) lanzan TypeError.
- Commits: `tienda: añade formatearEuros al ticket` (esta sesión).
- Riesgos: ninguno.
- Siguiente paso: `ticket-002` (Línea de ticket).

### 2026-10-16 · Pi · ticket-002 (Línea de ticket)

- Objetivo: implementar `lineaTicket(linea)` en `src/ticket.js` y su prueba en `test/ticket.test.js`.
- Completado: función que devuelve `"<cantidad> x <nombre>  <precio> = <importe>"` usando `formatearEuros`
  (`precio * cantidad` se redondea a céntimos al formatear). Pruebas añadidas: varias unidades, una unidad
  y redondeo a céntimos.
- Verificación ejecutada: `node --test test/ticket.test.js` → 6 pass / 0 fail; `npm test` → 21 pass / 0 fail.
- Evidencia: `{ nombre: 'Taza', precio: 4.5, cantidad: 2 }` → `"2 x Taza  4,50 € = 9,00 €"`;
  `{ nombre: 'Bolígrafo', precio: 0.1, cantidad: 3 }` → `"3 x Bolígrafo  0,10 € = 0,30 €"`.
- Commits: `tienda: añade lineaTicket al ticket`; `tienda: añade pruebas de lineaTicket al ticket` (esta sesión).
- Riesgos: ninguno.
- Siguiente paso: `ticket-003` (Ticket completo).

### 2026-10-16 · Pi · ticket-003 (Ticket completo)

- Objetivo: implementar `ticket(lineas, cupon)` en `src/ticket.js` y sus pruebas en `test/ticket.test.js`.
- Completado: función que devuelve el texto completo (una línea por producto, «Envío  <importe>» y «Total  <importe>»),
  reutilizando `lineaTicket`, `gastosEnvio(totalConCupon(lineas, cupon))` y `totalConEnvio(lineas, cupon)`. Pruebas
  añadidas: por debajo del umbral con cupón (envío 4,95 €) y por encima sin/con cupón (envío 0,00 €).
- Verificación ejecutada: `./verificar.sh ticket-003` → exit 0; `npm test` → 24 pass / 0 fail.
- Evidencia: `{ Mochila 30×1, Libreta 4×3 }` con cupón 10 % → `Total  50,69 €` (envío 4,95 €);
  `{ Silla 45×1 }` → `Total  54,45 €` (envío 0,00 €).
- Commits: `tienda: añade ticket completo al ticket` (esta sesión).
- Riesgos: ninguno.
- Siguiente paso: ninguno (todas las funcionalidades en `pasa`).

### 2026-10-17 · omp · ticket-004 (Desglose del pedido)

- Objetivo: implementar `desglose(lineas, cupon, tipoIVA = 21)` en `src/desglose.js` y sus pruebas en
  `test/desglose.test.js`.
- Completado: función que devuelve `{ base, iva, envio, total }` en euros redondeados a céntimos, reutilizando
  `totalConCupon` (base), `aplicarIVA(base, tipoIVA) − base` (iva, redondeado a céntimos), `gastosEnvio(base)`
  (envio) y `totalConEnvio(lineas, cupon, tipoIVA)` (total). Pruebas añadidas: 6 pedidos con importes escritos a
  mano (sin cupón y con el 10 %, por debajo, justo en y por encima del umbral de 40 €, y un tipo de IVA del 10 %)
  más la invariante base + iva + envio = total en cada uno.
- Verificación ejecutada: `./verificar.sh ticket-004` → exit 0 (A1–A5 en verde; aceptación 4 pass / 0 fail);
  `node --test test/desglose.test.js` → 12 pass / 0 fail; `npm test` → 36 pass / 0 fail.
- Evidencia: `{ Mochila 30×1, Libreta 4×3 }` con cupón 10 % → `{ base: 37.8, iva: 7.94, envio: 4.95,
  total: 50.69 }`; `{ Silla 45×1 }` sin cupón → `{ base: 45, iva: 9.45, envio: 0, total: 54.45 }`; con cupón
  10 % (40,50 €) → `{ base: 40.5, iva: 8.51, envio: 0, total: 49.01 }`.
- Commits: `tienda: añade el desglose del pedido` (esta sesión).
- Riesgos: ninguno. `src/carrito.js`, `src/envio.js` y `src/ticket.js` no se han tocado (contrato de la rúbrica).
- Siguiente paso: ninguno (todas las funcionalidades en `pasa`).
