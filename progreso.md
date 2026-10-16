# Progreso

Registro de sesiones de la tienda, para cualquier agente. Se lee al empezar y se actualiza al terminar, porque así lo
pide `AGENTS.md`; ningún agente lo actualiza solo.

## Estado verificado

- Raíz del repositorio: `~/csn/tienda`, rama `andamiaje`
- Arranque estándar: `./init.sh`
- Verificación estándar: `npm test`
- Funcionalidad en curso: ninguna; `ticket-001`, `ticket-002` y `ticket-003` en `pasa`
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

- Objetivo: marcar `ticket-003` como `pasa` con la evidencia de `npm test`.
- Hallazgo: `npm test` pasaba (24/24), pero la aceptación `aceptacion/ticket-003.mjs` fallaba. `ticket()` calculaba
  los gastos de envío sobre `subtotal(lineas)` en lugar de sobre el total con cupón sin IVA, así que un cupón que
  cruzaba el umbral de 40 € descontaba el envío indebidamente. `npm test` no lo detectaba porque ninguna prueba
  unitaria cubría ese caso.
- Completado: `ticket()` usa `gastosEnvio(totalConCupon(lineas, cupon))` y `totalConEnvio(lineas, cupon)`; se añadió
  una prueba de regresión (subtotal 42 €, cupón 10 % → 37,80 € con envío). No se tocó la verificación.
- Verificación ejecutada: `node --test test/ticket.test.js` → 10 pass / 0 fail; `npm test` → 25 pass / 0 fail;
  `node --test aceptacion/ticket-003.mjs` → 1 pass / 0 fail.
- Evidencia: el ticket del caso de aceptación termina en `Total: 50,69 €`, igual a `totalConEnvio(lineas, cupon)`.
- Commits: `tienda: corrige el cálculo del envío en el ticket`; `tienda: añade prueba de regresión del envío con cupón`;
  `tienda: marca ticket-003 como pasa` (esta sesión).
- Riesgos: ninguno.
- Siguiente paso: ninguna funcionalidad pendiente.
