# Rúbrica de ticket-004 · Desglose del pedido

Adaptado de Learn Harness Engineering, © 2025 WalkingLab, licencia MIT
(https://github.com/walkinglabs/learn-harness-engineering; ver `LICENSE-learn-harness-engineering`): plantilla del
evaluador y *sprint contract*. Escrita antes del trabajo; quien implementa no la cambia.

## Contrato

- **Alcance:** `src/desglose.js` y `test/desglose.test.js`.
- **Fuera de alcance:** `src/carrito.js`, `src/envio.js`, `src/ticket.js` y las otras funcionalidades.
- **Verificación:** `./verificar.sh ticket-004`.

## Criterios automáticos (los comprueba `verificar.sh`)

| Id | Capa | Criterio |
|----|------|----------|
| A1 | Estática | `node --check` de `src/*.js` |
| A2 | Ejecución | `npm test` pasa |
| A3 | Sistema | Pasa la prueba de aceptación `aceptacion/ticket-004.mjs` |
| A4 | Evidencia | Ninguna funcionalidad en `pasa` con `evidencias` vacío |
| A5 | Verificación intacta | `rubricas/`, `aceptacion/` y `verificar.sh` sin cambios desde la última etiqueta `rubrica-*` |

## Criterios de juicio (0–2; los puntúa un revisor con evidencia fichero:línea)

| Id | Criterio | 0 | 1 | 2 |
|----|----------|---|---|---|
| J1 | Alcance | Toca ficheros fuera del contrato | Solo los del contrato, con cambios que no pide la tarea | Solo los del contrato, sin refactorizar nada más |
| J2 | Pruebas con sentido | Las pruebas repiten el cálculo de la implementación | Comprueban importes escritos a mano en un solo lado del umbral de envío | Importes escritos a mano en los dos lados del umbral, con y sin cupón, sin repetir el cálculo |
| J3 | Traspaso | Recalcula lo que ya existe | Reutiliza a medias | Reutiliza `totalConCupon`, `aplicarIVA`, `gastosEnvio` y `totalConEnvio` y se entiende sin la conversación |

## Veredicto

- **Aceptar:** todo 2, o un solo 1 justificado.
- **Revisar:** algún 1.
- **Bloquear:** algún 0 o cualquier criterio automático en rojo.
