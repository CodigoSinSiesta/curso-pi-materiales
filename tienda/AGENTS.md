# tienda

Tienda de juguete para las demos del curso. JavaScript (ESM) sin dependencias; pruebas con `node --test`.

Andamiaje para sesiones largas adaptado de Learn Harness Engineering (© 2025 WalkingLab, licencia MIT,
https://github.com/walkinglabs/learn-harness-engineering); ver `LICENSE-learn-harness-engineering`.

## Al empezar
1. `pwd`, para confirmar la carpeta.
2. Lee `progreso.md` y, si tiene contenido, `traspaso.md`.
3. Lee `funcionalidades.json` y elige la funcionalidad `en_curso` o, si no hay, la `sin_empezar` de más prioridad.
4. `git log --oneline -5`.
5. `./init.sh`. Si las pruebas ya fallan, arréglalo antes de tocar nada más.

## Mapa
- `src/carrito.js`: subtotal, cupones, IVA y total con envío.
- `src/envio.js`: gastos de envío.
- `test/`: una prueba por función pública.
- `funcionalidades.json`: qué hay que hacer y en qué estado está. Fuente de verdad del trabajo.
- `progreso.md`: estado verificado y registro de sesiones. `traspaso.md`: lo que queda a medias.

## Reglas
- Una tarea cada vez; no toques ficheros que la tarea no necesita.
- Solo una funcionalidad `en_curso` a la vez.
- Una funcionalidad pasa a `pasa` solo con su verificación ejecutada y la evidencia anotada (comando y resultado).
- No cambies la verificación de una funcionalidad para que pase.
- Importes en euros, redondeados a céntimos con `Math.round(x * 100) / 100`.
- Mensajes de commit en español y en imperativo, empezando por `tienda:`.

## Hecho significa
- Una funcionalidad pasa solo si `./verificar.sh <id>` sale con 0; la evidencia es su salida.
- No toques `rubricas/`, `aceptacion/` ni `verificar.sh`.

## Al terminar
1. Actualiza `funcionalidades.json` (estado, evidencias y notas) y `progreso.md` (estado verificado y una entrada
   para esta sesión).
2. Si queda algo a medias, escribe `traspaso.md`; si no, déjalo vacío.
3. Haz commit solo si `npm test` pasa.
4. Deja el repositorio listo para que la siguiente sesión ejecute `./init.sh` sin arreglos.
