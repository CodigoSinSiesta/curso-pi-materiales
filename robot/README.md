# El robot: un encargo desatendido (vídeo 28)

oh my pi lanzado a mano, por cron o por un webhook, que trabaja en un worktree con un perfil propio, lo juzga un programa
y, si pasa, deja una rama y una petición de cambios en el repositorio de revisión. Ideas adaptadas del curso abierto
*Building a Coding Agent From Scratch*, de Decoding AI (Apache-2.0); el código es nuestro (MIT).

| Fichero | Qué hace |
|---|---|
| `lanzar.sh <ticket-NNN\|siguiente>` | El lanzador: valida el identificador, cerrojo, idempotencia y presupuesto diario; worktree y manifiesto; `omp -p` con el perfil `robot`, la puerta y los topes; juez de fuera (`verificar.sh` desde la etiqueta y la prueba oculta); entrega con `git push` al remoto `revision` y `git request-pull`. Sale con 0 entregado, 1 verificación, 2 rechazado, 3 coste, 4 presupuesto, 5 ocupado, 6 infraestructura, 7 tiempo. |
| `webhook.mjs` | Receptor en `127.0.0.1:8787`: `POST /encargo` con `{"ticket":"ticket-NNN"}` y `Authorization: Bearer $ROBOT_TOKEN`. 401, 400, 409 y 503 sin lanzar nada; 202 y `lanzar.sh` en segundo plano. Sin dependencias. |
| `resumen-robot.sh [AAAAMMDD]` | Una fila por ejecución y el gasto del día frente al presupuesto. |
| `perfil/config.yml` | El perfil de oh my pi del robot: modo `write`, lista blanca de `bash.patterns`, órdenes compuestas, carpetas restringidas, `eval` denegado. Cópialo a `~/.omp/profiles/robot/agent/config.yml`. |
| `crontab.ejemplo`, `launchd/com.codigosinsiesta.robot.plist` | Los dos relojes, para copiar a mano. No se instalan solos. |

Lo que necesita:
- La tienda en la rama `robot` (sale de `ticket-005` con la rúbrica de `ticket-006` y la etiqueta `rubrica-ticket-006`),
  el remoto `revision` (`~/csn/remoto/tienda.git`, del vídeo 26) y `~/csn/fuera/ticket-006-oculta.mjs`.
- `DEEPSEEK_API_KEY` en el entorno. cron no carga tu shell: la línea de ejemplo la carga antes.
- `ROBOT_TOKEN` para el webhook: genéralo (`openssl rand -hex 16`) y no lo escribas en ningún fichero del repositorio.

Avisos:
- **Aprobar no es aislar.** Los patrones deciden qué órdenes se ejecutan, no qué hace una orden permitida: `npm test`
  ejecuta las pruebas que acaba de escribir el agente. Para aislar de verdad, un contenedor con una sola carpeta montada
  (vídeos 05 y 22), y la credencial para escribir en el repositorio siempre fuera.
- La lista blanca tiene que incluir la rutina de `AGENTS.md` (`./init.sh`): en el primer ensayo del vídeo no estaba, el
  robot no pudo ejecutar nada y no entregó.
- En Pi no hay tope de coste: `extensiones/tope.ts` corta el turno al pasar de `PI_TOPE_USD`, y Pi sale con 0 igualmente,
  así que el lanzador tiene que leer los eventos, no el código de salida.
