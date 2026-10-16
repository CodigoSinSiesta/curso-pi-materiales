# Rúbrica de ticket-003 · Ticket completo

Adaptado de Learn Harness Engineering, © 2025 WalkingLab, licencia MIT
(https://github.com/walkinglabs/learn-harness-engineering; ver `LICENSE-learn-harness-engineering`): plantilla del
evaluador y *sprint contract*. Escrita antes del trabajo; quien implementa no la cambia.

## Contrato

- **Alcance:** `src/ticket.js` y `test/ticket.test.js`.
- **Fuera de alcance:** `src/carrito.js`, `src/envio.js`, las otras funcionalidades y el formato de `formatearEuros`.
- **Verificación:** `./verificar.sh ticket-003`.

## Criterios automáticos (los comprueba `verificar.sh`)

| Id | Capa | Criterio |
|----|------|----------|
| A1 | Estática | `node --check` de `src/*.js` |
| A2 | Ejecución | `npm test` pasa |
| A3 | Sistema | Pasa la prueba de aceptación `aceptacion/ticket-003.mjs` |
| A4 | Evidencia | Ninguna funcionalidad en `pasa` con `evidencias` vacío |
| A5 | Verificación intacta | `rubricas/`, `aceptacion/` y `verificar.sh` sin cambios desde la etiqueta `rubrica-ticket-003` |

## Criterios de juicio (0–2; los puntúa un revisor con evidencia fichero:línea)

| Id | Criterio | 0 | 1 | 2 |
|----|----------|---|---|---|
| J1 | Alcance | Toca ficheros fuera del contrato | Solo los del contrato, con cambios que no pide la tarea | Solo los del contrato, sin refactorizar nada más |
| J2 | Pruebas con sentido | Repiten el cálculo de la implementación | Cubren un lado del umbral de envío | Cubren los dos lados del umbral, con y sin cupón, sin repetir el cálculo |
| J3 | Traspaso | Recalcula lo que ya existe | Reutiliza a medias | Reutiliza `totalConEnvio` y `formatearEuros` y se entiende sin la conversación |

## Veredicto

- **Aceptar:** todo 2, o un solo 1 justificado.
- **Revisar:** algún 1.
- **Bloquear:** algún 0 o cualquier criterio automático en rojo.
