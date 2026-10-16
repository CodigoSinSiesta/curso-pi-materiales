# Progreso

Registro de sesiones de la tienda, para cualquier agente. Se lee al empezar y se actualiza al terminar, porque así lo
pide `AGENTS.md`; ningún agente lo actualiza solo.

## Estado verificado

- Raíz del repositorio: `~/csn/tienda`, rama `andamiaje`
- Arranque estándar: `./init.sh`
- Verificación estándar: `npm test`
- Funcionalidad en curso: ninguna; no quedan funcionalidades pendientes
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
- Completado: una línea por producto con `lineaTicket`, la línea del envío y la del total, formateadas con
  `formatearEuros`. Pruebas con un carrito de 20 € (con y sin cupón) y otro de 60 € con cupón.
- Verificación ejecutada: `npm test` → 24 pass / 0 fail.
- Evidencia: todas las pruebas pasan.
- Commits: `tienda: añade ticket`; `tienda: marca ticket-003 como pasa` (esta sesión).
- Riesgos: ninguno.
- Siguiente paso: ninguno; las tres funcionalidades pasan.
