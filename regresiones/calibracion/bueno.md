## Resumen

- **Alcance correcto:** solo se modifican `src/carrito.js` y `test/carrito.test.js`; `src/envio.js`, `src/ticket.js`, `src/desglose.js`, `rubricas/`, `aceptacion/` y `verificar.sh` quedan intactos. Los cambios en `funcionalidades.json` y `progreso.md` son la contabilidad exigida por `AGENTS.md`.
- **Implementación:** `totalConCupon` detecta el cupón `{ importe }`, valida que sea un número finito mayor que 0, resta el importe una sola vez reutilizando `subtotal(lineas)`, aplica `Math.max(0, …)` y redondea a céntimos con el patrón de la tienda. El camino del cupón `{ porcentaje }` no cambia.
- **Integración:** `totalConEnvio`, `desglose` y `ticket` siguen usando `totalConCupon` sin cambios, por lo que el descuento se aplica antes del IVA y del envío. La aceptación de `ticket-005` verifica los dos lados del umbral de 40 €.
- **Pruebas:** cubren varias líneas, pedido por debajo del umbral con envío, total exacto de 40 €, cupón mayor que el pedido e importes inválidos. Los importes están escritos a mano, no recalculados con la implementación.
- **Evidencias:** los recuentos anotados cuadran con los ficheros actuales: 17 pruebas de carrito y 41 en total (`17 + 9 + 3 + 12`). No hay funcionalidades en `pasa` sin evidencias.
- **Rúbrica:** J1, J2 y J3 se cumplen; no hay refactorizaciones ajenas ni cambios en la verificación.

## Riesgos

- **Menor, no bloqueante:** la condición `cupon.importe !== undefined` hace que `{ importe: undefined }` no entre en la validación y caiga en la rama porcentual, devolviendo `NaN` en lugar de `TypeError`. No está cubierto por las pruebas ni por la aceptación. Si se quiere ser estricto con «un importe que no sea un número finito mayor que 0», convendría comprobar `'importe' in cupon`.
- **Precedencia no especificada:** un cupón con `importe` y `porcentaje` a la vez aplica solo el importe. No es un caso definido por el contrato, pero conviene tenerlo presente.
- **Sin impacto:** los riesgos anteriores no afectan a los casos del contrato ni a la verificación automática.

VEREDICTO: OK
