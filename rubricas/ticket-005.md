# Rúbrica de ticket-005 · Cupón de importe fijo

Adaptado de Learn Harness Engineering, © 2025 WalkingLab, licencia MIT
(https://github.com/walkinglabs/learn-harness-engineering; ver `LICENSE-learn-harness-engineering`): plantilla del
evaluador y *sprint contract*. Escrita antes del trabajo; quien implementa no la cambia.

## Contrato

- **Alcance:** `src/carrito.js` (`totalConCupon`) y `test/carrito.test.js`.
- **Fuera de alcance:** `src/envio.js`, `src/ticket.js`, `src/desglose.js`, sus pruebas y las otras funcionalidades.
- **Verificación:** `./verificar.sh ticket-005`.

## Criterios automáticos (los comprueba `verificar.sh`)

| Id | Capa | Criterio |
|----|------|----------|
| A1 | Estática | `node --check` de `src/*.js` |
| A2 | Ejecución | `npm test` pasa |
| A3 | Sistema | Pasa la prueba de aceptación `aceptacion/ticket-005.mjs` |
| A4 | Evidencia | Ninguna funcionalidad en `pasa` con `evidencias` vacío |
| A5 | Verificación intacta | `rubricas/`, `aceptacion/` y `verificar.sh` sin cambios desde la última etiqueta `rubrica-*` |

## Criterios de juicio (0–2; los puntúa un revisor con evidencia fichero:línea)

| Id | Criterio | 0 | 1 | 2 |
|----|----------|---|---|---|
| J1 | Alcance | Toca ficheros fuera del contrato | Solo los del contrato, con cambios que no pide la tarea | Solo los del contrato, sin refactorizar nada más |
| J2 | Pruebas con sentido | Las pruebas repiten el cálculo de la implementación | Importes escritos a mano, sin el caso de un cupón mayor que el pedido o sin el de varias líneas | Importes escritos a mano con varias líneas, en el umbral, con un cupón mayor que el pedido y con un importe no válido |
| J3 | Reutilización | Recalcula lo que ya existe o cambia el cupón de porcentaje | Reutiliza a medias | Reutiliza `subtotal` y el redondeo de la tienda, deja intacto el cupón de porcentaje y se entiende sin la conversación |

## Veredicto

- **Aceptar:** todo 2, o un solo 1 justificado.
- **Revisar:** algún 1.
- **Bloquear:** algún 0 o cualquier criterio automático en rojo.
