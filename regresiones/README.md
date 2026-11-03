# Regresiones del agente (vídeo 27)

Convertir un fallo del agente en un caso que se ejecuta solo, y reproducirlo con el mismo modelo, con otro y con un
arreglo del harness para saber de quién era el fallo. Ideas adaptadas del curso abierto *Building a Coding Agent From
Scratch*, de Decoding AI (Apache-2.0); el código de esta carpeta es nuestro (MIT, como el resto de los materiales).

| Fichero | Qué hace | ¿Gasta modelo? |
|---|---|---|
| `minar.sh <carpeta…>` | Recorre sesiones de Pi y de oh my pi: errores de herramienta, respuestas en error o abortadas, tokens y coste. Agrupa por firma (herramienta + primera línea + modelo) y tapa tu carpeta personal. | No |
| `casos/*.json` | Un caso: síntoma, origen, punto de partida, orden, opciones, topes, comprobaciones y, si hace falta, la afirmación del juez. | — |
| `comprobaciones/*.sh <worktree> <ejecución>` | Salen con 0 o 1: `arbol-limpio`, `sin-error`, `tope-coste`, `verificar`, `oculta` y `afirmacion` (la del juez). | Solo `afirmacion` |
| `juez.sh <caso> <texto>` | Pi sin herramientas y con un modelo barato: ¿el texto cumple la afirmación del caso? | Sí, poco |
| `calibracion/bueno.md`, `malo.md` | El informe de la CI del vídeo 26 (señala el borde) y la revisión de Pro (no lo señala). El juez tiene que dar PASA y FALLA. | — |
| `arreglos/revisor-bordes.md` | La instrucción que se prueba como arreglo del harness (`ARREGLO=` en `reproducir.sh`). | — |
| `reproducir.sh <caso> <n>` | n repeticiones desde cero: worktree en el commit de partida, manifiesto, `omp -p` y las comprobaciones. `MODELO=` cambia solo el modelo; `ARREGLO=` añade un fichero al system prompt. | Sí |
| `regresiones.sh <n>` | La batería: todos los casos, n veces, y salida 0 o 1 según `UMBRAL`. | Sí |
| `resumen-regresiones.sh [tanda…]` | Una fila por ejecución, pasó alguna vez y pasó todas por caso, y la infraestructura aparte. | No |
| `comprobar-archivo.sh <comprobación> <caso> <carpeta>` | Pasa una comprobación de código por sesiones ya grabadas, sin repetir ninguna. | No |
| `rpc-bifurcar.mjs pi\|omp <copia>` | Vuelve a un punto de una sesión por RPC (Pi: `fork`; oh my pi: `navigate_tree`). | No |

Avisos:
- **No abras nunca la sesión original: trabaja sobre una copia.** Abrir una sesión de oh my pi le añade una entrada de
  cierre de proceso; la original es la evidencia del fallo.
- Los resultados van a `resultados/<caso>/<tanda>-<n>/` (manifiesto, eventos, sesión, respuesta, comprobaciones). No
  los guardes en `/tmp`: si una sesión puede acabar siendo un caso, que no se borre sola.
- Los casos usan la tienda (`~/csn/tienda`, ramas `final` y `ticket-005`, etiqueta `rubrica-ticket-005`) y la prueba
  oculta de `~/csn/fuera/`. Hace falta `DEEPSEEK_API_KEY` en el entorno: sin ella, oh my pi caería a otro modelo.
- Tres repeticiones dan una pista, no una estadística. Y en cuanto la batería decide si actualizas, se vuelve objetivo:
  guarda casos que no hayas usado para escribir el arreglo.
