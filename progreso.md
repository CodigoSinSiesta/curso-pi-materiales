# Progreso

Registro de sesiones de la tienda, para cualquier agente. Se lee al empezar y se actualiza al terminar, porque así lo
pide `AGENTS.md`; ningún agente lo actualiza solo.

## Estado verificado

- Raíz del repositorio: `~/csn/tienda`, rama `andamiaje`
- Arranque estándar: `./init.sh`
- Verificación estándar: `npm test`
- Funcionalidad en curso: `ticket-002` (Línea de ticket), sin pruebas todavía
- Siguiente funcionalidad: `ticket-003` (Ticket completo)
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

### 2026-10-16 · Pi · ticket-002 (Línea de ticket) — en curso

- Objetivo: implementar `lineaTicket(linea)` en `src/ticket.js`; de momento solo la función, sin pruebas.
- Completado: función que devuelve `"<cantidad> x <nombre>  <precio> = <importe>"` usando `formatearEuros`
  (`precio * cantidad` se redondea a céntimos al formatear).
- Verificación ejecutada: `npm test` → 18 pass / 0 fail (no hay pruebas nuevas de `lineaTicket`).
- Evidencia manual: `{ nombre: 'Taza', precio: 4.5, cantidad: 2 }` → `"2 x Taza  4,50 € = 9,00 €"`.
- Commits: `tienda: añade lineaTicket al ticket` (esta sesión).
- Riesgos: `ticket-002` sigue `en_curso` y sin prueba; no se marca `pasa` sin la verificación del JSON.
- Siguiente paso: añadir `test/ticket.test.js` para `lineaTicket` y ejecutar la verificación.
