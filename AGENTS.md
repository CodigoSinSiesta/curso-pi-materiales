# tienda

Tienda de juguete para las demos del curso. JavaScript (ESM) sin dependencias; pruebas con `node --test`.

## Al empezar
1. `git status` y `git log --oneline -5`.
2. `npm test`. Si ya falla, arréglalo antes de tocar nada más.

## Mapa
- `src/carrito.js`: subtotal, cupones, IVA y total con envío.
- `src/envio.js`: gastos de envío.
- `test/`: una prueba por función pública.

## Reglas
- Una tarea cada vez; no toques ficheros que la tarea no necesita.
- Importes en euros, redondeados a céntimos con `Math.round(x * 100) / 100`.
- Mensajes de commit en español y en imperativo, empezando por `tienda:`.

## Hecho significa
- Has añadido o actualizado la prueba del cambio.
- Has ejecutado `npm test` y pasa.
- Has resumido qué cambió y cómo lo verificaste.
