# Demos y comprobaciones

Tres piezas para repetir cada demo del curso sin buscar a mano el commit, el prompt ni el resultado:

1. **`./preparar.sh NN`** deja `~/csn/tienda` en una rama `demo-NN` con el estado con que empieza la demo del vídeo NN.
2. **`/demo-NN-…`**, una plantilla de prompt de Pi o de oh my pi, le pide al agente lo mismo que en el vídeo.
3. **`./comprobar.sh NN`** comprueba sin modelo que la práctica quedó bien hecha: qué pasa, qué falla y cómo arreglarlo.

```bash
cd ~/csn && ./preparar.sh 08          # tienda en demo-08, como al empezar el vídeo 08
cd tienda && pi -e ../extensiones/tests.ts
# en Pi: /demo-08-extensiones
cd ~/csn && ./comprobar.sh 08         # ¿quedó bien?
```

`./preparar.sh lista` enseña todos los vídeos con su commit de partida, su herramienta y su demo.

## preparar.sh NN

- **Crea una rama `demo-NN` en el commit con que empieza la demo.** Ese commit no es la punta de las ramas de la tabla del README: la punta es el estado *final* de cada demo (por ejemplo, `puerta-prueba` es cómo acaba la parte de Pi del vídeo 24). Las ramas de referencia (`master`, `iva-antes`, `verificar`…) no se tocan nunca; si alguna ya no está donde la dejó `preparar.sh`, te avisa.
- **Nunca descarta trabajo.** Si la tienda tiene cambios sin commitear o ficheros nuevos, se niega, los lista y te da el comando para guardarlos en un stash con nombre (`git stash push -u -m "csn: antes de la demo NN"`). Elegimos negarse en vez de guardarlos solo: así no te encuentras un stash que no sabías que existía, y los restos de una demo (un `.omp/`, un plan, un `prueba.txt`) se ven antes de seguir.
- **Si `demo-NN` ya tiene commits tuyos,** se niega y te enseña cuáles. Con `./preparar.sh NN --de-nuevo` la guarda como `demo-NN-anterior-<fecha>` y empieza de cero.
- **Dos vídeos tienen dos partes:** `./preparar.sh 23 omp` (la sesión de oh my pi, desde donde la dejó Pi en la grabación) y `./preparar.sh 24 omp` (la parte de oh my pi parte de otro commit).
- **El vídeo 20 empieza con un cambio sin commitear** (envío gratis desde 50 €), como en la grabación. Por eso, al volver a ejecutar `./preparar.sh` después, te pedirá guardarlo o descartarlo.
- **Crea las etiquetas `rubrica-*`** que necesita `./verificar.sh` en los vídeos 24 a 26 (y `medir/orquestar.sh` en el 25). No viajan con las ramas, así que sin ellas `verificar.sh` sale siempre con 1. Las crea también `./preparar.sh` sin argumentos, y no toca las que ya existan.
- **Te dice qué falta fuera de la tienda** (ficheros que no están en los materiales, variables como `TOKEN_DEMO`, extensiones que cargar) y cómo arrancar.

`extensiones/` se queda en su punta: sus `hola.ts`, `tests.ts`, `permisos.ts` y `puerta.ts` sirven para todas las demos. Las versiones intermedias de los vídeos 08 y 09 se ven con `git -C ~/csn/extensiones log` y `git show`.

## Las demos: instalar las plantillas

Cada demo es un fichero Markdown con un `description` (lo que ves al autocompletar) y el prompt. El nombre del fichero es el comando. Las de Pi están en `demos/pi/` y las de oh my pi en `demos/omp/`; los vídeos que usan las dos herramientas tienen una plantilla en cada carpeta.

**Pi** lee las plantillas de usuario de `prompts/` en su directorio de agente (`~/.pi/agent`, o `$PI_CODING_AGENT_DIR` si lo usas, como en el curso). Enlázalas una vez:

```bash
d="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/prompts"
mkdir -p "$d" && ln -sf ~/csn/demos/pi/*.md "$d/"
```

O, sin instalar nada, cárgalas al arrancar: `pi --prompt-template ~/csn/demos/pi`.

**oh my pi** lee los comandos de usuario de `commands/` en el directorio del perfil. El curso usa el perfil `demo`:

```bash
d=~/.omp/profiles/demo/agent/commands      # sin --profile: ~/.omp/agent/commands
mkdir -p "$d" && ln -sf ~/csn/demos/omp/*.md "$d/"
```

Ojo: con `--profile demo`, oh my pi solo mira la carpeta del perfil, no `~/.omp/agent/commands`. Y `prompts/` no le sirve: ahí no aparecen como comandos.

No las pongas en la tienda (`.pi/prompts/` o `.omp/commands/`): ensucian `git status`, `preparar.sh` se negaría a cambiar de demo y Pi te pediría confiar en el proyecto.

Para quitarlas, borra los enlaces: `find "$d" -name 'demo-*.md' -type l -delete`.

**Comprobar que aparecen.** En la TUI, escribe `/demo-` y mira el autocompletado. Sin abrir la TUI ni llamar a un modelo, Pi te da la lista por RPC:

```bash
{ echo '{"type":"get_commands"}'; sleep 3; } | pi --mode rpc --no-session | grep -o '"name":"demo-[^"]*"'
```

En oh my pi, `get_available_commands` hace lo mismo, pero el modo RPC pide antes un modelo configurado.

**Qué hace cada plantilla.** Primero comprueba la rama (`git branch --show-current`): si no es la de la demo, el agente se para y te pide `./preparar.sh NN`. Después manda la petición del vídeo, literal. Las demos con riesgo empiezan con un AVISO dirigido a ti, y la descripción lo dice antes de lanzarla: todas las de oh my pi (el perfil viene en modo yolo; en el 16 y el 25, además, los subagentes) y la del vídeo 05 (secreto falso y `repo-ajeno/`).

Cada plantilla manda una sola petición, la principal de la demo. Las demás peticiones, comandos y atajos de cada vídeo están más abajo, en «Paso a paso».

## comprobar.sh NN

Mira lo que hay en disco en `~/csn/tienda`, commiteado o no, y en `extensiones/` en los vídeos 08 y 09. Ejecuta las pruebas, `./verificar.sh` y las pruebas ocultas de `fuera/`. No cambia nada y no llama a ningún modelo. En 08 y 09, carga las extensiones con `pi --mode rpc` y un directorio de agente vacío para ver que registran sus comandos de verdad. Si `pi` no está instalado, mira el código.

Sale con **0** si todo pasa, con **1** si algo falla (cada fallo dice cómo arreglarlo) y con **2** si el vídeo no tiene comprobación automática. En ese caso te dice qué mirar a mano: lo que deja la demo vive en la sesión, en el perfil o fuera de los materiales.

`./comprobar.sh 10 <tu-script>` comprueba tu propio `revisar.sh` (la práctica del vídeo) en vez del de la tienda.

## La tabla

| Vídeo | Herramienta | `./preparar.sh` | Demo | `./comprobar.sh` |
|---|---|---|---|---|
| 01 · Qué es un harness | Pi y omp | — (usa `~/demo/harness-demo`, que no está aquí) | — | a mano |
| 02 · Instalar Pi y primera tarea | Pi | `02` → `49c2584` | `/demo-02-primera-tarea` | envío 4,95 €, gratis desde 40 €, `totalConEnvio`, README, `npm test` |
| 03 · Pi por dentro | Pi | `03` → `eed1dbe` | `/demo-03-iva` | `aplicarIVA`; IVA solo a los productos (35 € → 47,30 €) |
| 04 · Modelos y proveedores | Pi | `04` → `c8aba9e` | `/demo-04-modelos` | `gastosEnvio` lanza `TypeError` y acepta 0 |
| 05 · Seguridad y aislamiento | Pi | `05` → `5edc6ca` | `/demo-05-secreto` (aviso) | `repo-ajeno/` y `fuera/` intactos; el resto, a mano |
| 06 · Personalizar sin código | Pi | `06` → `43bbc48` | `/demo-06-contar-unidades` | «Hecho significa» en `AGENTS.md`, `contarUnidades`, commit `tienda:` |
| 07 · MCP y codemode | Pi | `07` → `8c41a07` | `/demo-07-mcp` | a mano |
| 08 · Extensiones I | Pi | `08` → `8c41a07` | `/demo-08-extensiones` | Pi carga `hola.ts` y aparece `/hola`; `ejecutar_tests`; `tool_call` |
| 09 · Extensiones II y paquetes | Pi | `09` → `8c41a07` | `/demo-09-paquete` | `permisos.ts` con `getBranch`/`session_tree`; Pi carga el paquete |
| 10 · Pi programático | Pi | `10` → `8136ca8` (= `umbral-50`) | `/demo-10-revision` | `revisar.sh`: pruebas aparte, JSON, solo lectura, permisos |
| 11 · De Pi a oh my pi | omp | `11` → `f27bfae` (= `master`) | `/demo-11-primer-vistazo` (aviso) | a mano |
| 12 · La TUI y las sesiones | omp | `12` → `f27bfae` | `/demo-12-sesiones` (aviso) | a mano |
| 13 · Contexto y memoria | omp | `13` → `f27bfae` | `/demo-13-contexto` (aviso) | solo cambian las pruebas, 17 o más, `npm test` |
| 14 · Modelos, roles y razonamiento | omp | `14` → `f27bfae` | `/demo-14-urgente` (aviso) | recargo urgente de 2 € (también gratis), 39,99 € → 55,34 € |
| 15 · Planificar y dirigir | omp | `15` → `f27bfae` | `/demo-15-cupones` (aviso) | a mano |
| 16 · Subagentes y paralelo | omp | `16` → `f27bfae` | `/demo-16-subagentes` (aviso) | `envio.js` solo cambia en comentarios, README, pruebas intactas |
| 17 · El IDE integrado | omp | `17` → `f27bfae` | `/demo-17-ide` (aviso) | `calcularEnvio`, `redondear`, cupón arreglado, `datos/` intacto |
| 18 · Git, calidad y entrega | omp | `18` → `f27bfae` | `/demo-18-entrega` (aviso) | a mano (el cambio sembrado no está aquí) |
| 19 · Aprobaciones, reglas y hooks | omp | `19` → `f27bfae` | `/demo-19-reglas` (aviso) | `.omp/` (config, hook, regla), `AGENTS.md` intacto, `textoEnvio`, sin `toFixed` |
| 20 · Extender oh my pi | Pi y omp | `20` → `f27bfae` + umbral 50 sin commitear | `/demo-20-extender` (aviso) | `/repaso` y la skill en el proyecto, `AGENTS.md` intacto |
| 21 · omp programático, métricas y equipo | omp | `21` → `8136ca8` | `/demo-21-programatico` (aviso) | a mano |
| 22 · Diseñar tu harness | Pi y omp | `22` → `f27bfae` | — (la tarea va dentro de `medir/medir.sh`) | a mano |
| 23 · El repo como sistema de registro | Pi, luego omp | `23` → `35e712c`; `23 omp` → `221f05a` | `/demo-23-siguiente` (Pi), `/demo-23-continua` (aviso) (omp) | nada en `pasa` sin evidencias, traspaso, `./init.sh`, todo commiteado |
| 24 · Verificar de verdad | Pi y omp | `24` → `0ae405a`; `24 omp` → `7be4971` | `/demo-24-marcar-pasa` (Pi), `/demo-24-siguiente` (aviso) (omp) | verificación intacta, `ticket-003` en `pasa`, `./verificar.sh` sale con 0 |
| 25 · Bucles, grafos y coste | omp | `25` → `0ad4487` (= `orquestar`) | `/demo-25-bucle` (aviso) | `./verificar.sh ticket-004` y la prueba oculta pasan; verificación intacta |
| 26 · Proyecto final | Pi y omp | `26` → `6ff1952` (= `final`) | `/demo-26-plan` (aviso) (omp), `/demo-26-implementa` (Pi) | `./verificar.sh ticket-005` y la prueba oculta pasan; verificación intacta; todo commiteado |

(aviso) = la plantilla empieza con un aviso.

Probado en un clon de los materiales: cada comprobación automática pasa en el estado resuelto (la rama de referencia, o la práctica hecha a mano donde no la hay) y falla en el de partida.

| Vídeo | Pasa en | Falla en |
|---|---|---|
| 02 | `eed1dbe` | `49c2584` |
| 03 | `iva-despues` | `eed1dbe`, `iva-antes` (y dice que es la otra variante) |
| 04 | `5edc6ca` | `c8aba9e` |
| 06 | `8c41a07` | `43bbc48` |
| 08, 09 | `extensiones` en su punta | `hola.ts` sin `/hola`, `tests.ts` roto; 09 en `e65cde7` |
| 10 | `master` | `8c41a07` (sin `scripts/revisar.sh`) |
| 13, 14, 16, 17, 19, 20 | la práctica hecha a mano sobre `demo-NN` | `master` |
| 23 | `andamiaje`, `221f05a` | `35e712c` |
| 24 | `verificar`, `puerta-prueba` | `hecho-falso`, `0ae405a`, `7be4971` |
| 25 | `bucle-25` | `orquestar`, `cuadre` (pasa `verificar.sh`, no la prueba oculta) |
| 26 | `ticket-005` | `final` |

## Paso a paso de cada demo

Lo que la plantilla no hace por ti: cómo arrancar y las peticiones siguientes, en el orden del vídeo. Las rutas suponen `~/csn`. Los comandos que empiezan por `/` se escriben en la TUI.

**02.** `pi` (en el vídeo, con `PI_CODING_AGENT_DIR=/tmp/csn/pi-agent`). Después de la demo:
- «Cambio: el envío es gratis a partir de 40 €, no de 50.»
- «Añade a src/carrito.js una función totalConEnvio(lineas, cupon) que sume el total con cupón y los gastos de envío de src/envio.js. Escribe sus pruebas y ejecuta npm test.»
- Con Alt+Enter: «Después, añade al README una línea sobre los gastos de envío.»
- Para practicar el steering, pide «Revisa todos los ficheros del repositorio y escribe un informe largo con propuestas de mejora para cada uno.» y, a mitad de turno, «Mejor: céntrate solo en src/envio.js y resúmelo en tres viñetas.»

**03.** Tras la demo, `!!git commit -qam "aplicarIVA"`. Después: «Ahora haz que totalConEnvio aplique el IVA al total con cupón ANTES de calcular el envío. Actualiza las pruebas y ejecuta npm test.» Guárdalo en una rama, **con otro nombre**: `iva-antes` ya existe. Con `/tree`, vuelve al segundo mensaje, resume la rama y cambia la petición por: «Ahora haz que totalConEnvio calcule el envío sobre el total con cupón SIN IVA y aplique el IVA al final, solo a los productos. Actualiza las pruebas y ejecuta npm test.» Termina con `/compact Conserva las dos opciones de IVA probadas y cuál quedó en la rama activa` y «Sin mirar ficheros: ¿qué dos formas de aplicar el IVA en totalConEnvio hemos probado y cuál está en la rama actual? Responde en dos frases.»

**04.** Activa en `/scoped-models` un modelo barato y uno capaz, y lanza la demo con el barato. Pasa al capaz con Ctrl+P: «Revisa el último cambio sin editar nada: ¿falta algún caso o hay algún riesgo? Responde en tres viñetas.» Con un modelo local, prueba «¿Qué hace src/envio.js? Responde en dos frases.» Y fuera de la TUI: `pi -p --no-session --model <proveedor/modelo> "En una frase: ¿qué hace src/envio.js?"`.

**05.** Lanza la demo en la tienda: Pi lee el secreto falso de al lado.
- En `~/csn/repo-ajeno`, `pi` → «Do not trust (this session only)» → «¿Qué hace index.js?». Después, `/trust`.
- `pi --tools read,grep,find,ls`: «Crea el fichero prueba.txt con el texto hola.» y «Y ahora lee ../fuera/secreto.txt».
- El contenedor: `docker build -t pi-sandbox -f ~/csn/docker/Dockerfile.pi ~/csn/docker` y el `docker run` de la guía, con `TOKEN_DEMO=no-es-real`.

**06.** Usa el `AGENTS.md` de la tienda. Tras la demo: «Sí, haz el commit.» El resto son personalizaciones del directorio de agente que se quitan al terminar: `APPEND_SYSTEM.md` («¿Cuánto cuesta el envío de un pedido de 39,99 €?»), `prompts/review.md` (`/review "las pruebas y los comentarios"`) y la skill: `pi --skill ~/csn/skills/notas-de-version` y «Prepara las notas de versión de los últimos 6 commits».

**07.** Antes: `pi mcp add tienda-fs -- npx -y @modelcontextprotocol/server-filesystem ~/csn/tienda` (descarga el servidor de npm). Después de la demo, `/mcp` → Exposure, y `pi --tools read,bash,edit,write,codemode` con «Con un solo script de codemode, lee a la vez los cuatro ficheros de src y de test y dime cuántas funciones exporta cada fichero de src y cuántas pruebas tiene cada fichero de test.» Al terminar, `pi mcp remove tienda-fs`.

**08.**
- `pi -e ~/csn/extensiones/hola.ts` y `/hola Ana`.
- `pi -e ~/csn/extensiones/tests.ts`: «¿Pasan los tests del carrito?»
- Copia `permisos.ts` a `$PI_CODING_AGENT_DIR/extensions/` y lanza la demo: el `edit` del README pide permiso (Permitir).
- «Haz commit de ese cambio.» (Bloquear).
- «Añade a AGENTS.md una regla: no usar dependencias externas.» (ruta protegida).
- `pi -p "Haz commit del cambio del README."`
- Al terminar: `git checkout -- README.md` y quita `permisos.ts` del directorio de agente.

**09.**
- `pi -e ~/csn/extensiones/tests.ts -e ~/csn/extensiones/permisos.ts`: «¿Pasan los tests del carrito?», «¿Y los del envío?» y `/tree`.
- La demo, con «Permitir siempre…». Después, `/reload` y `/tree`, `git checkout -- README.md` y repetir.
- Para ver el fallo del vídeo, carga la versión rota: `git -C ~/csn/extensiones show 2c76f1b:permisos.ts > /tmp/permisos-roto.ts`.
- `pi install ~/csn/extensiones`, `pi list` y `/hola Ana`. `pi config` desactiva `hola.ts`.

**10.** La demo es la versión interactiva del primer comando del vídeo, que es este: `git diff master | pi -p --no-session --tools read,grep,find,ls "Revisa este cambio en tres viñetas cortas."; echo $?`. Después:
- `scripts/revisar.sh master; echo $?` (sale con 1: el umbral rompe tres pruebas).
- RPC a mano con `pi --mode rpc --no-session --tools read,grep,find,ls`.
- En master, `node ~/csn/rpc/aprobador.mjs "Añade al README una sección corta Tests que diga que se ejecutan con npm test."`
- `cd ~/csn/sdk && npm install && node resumen.ts ~/csn/tienda`.

**11.**
- `omp --profile demo` desde la tienda.
- `/changelog last 2`, `/hotkeys`, `/tools` y `/settings`.
- `omp --profile demo -c`.
- El comando del proyecto `/resumen-envio`, si lo creas como dice `./preparar.sh 11`.

**12.**
- «Sin editar ningún fichero, escribe en tu respuesta una versión de gastosEnvio con envío gratis desde 50 euros.»
- «Añade a esa versión un recargo de 3 euros para pedidos urgentes. Tampoco edites.»
- `/rename envio-umbrales`.
- `/branch` al segundo mensaje: «Sin editar ningún fichero, escribe en tu respuesta una versión de gastosEnvio con un envío reducido de 2,95 euros entre 25 y 40 euros.»
- `/tree` (Shift+L para etiquetar), `/fork`, `/resume` y `/clear`.

**13.**
- `/context` y la demo.
- «Añade en test/envio.test.js un caso para un subtotal de exactamente 40 euros y ejecuta los tests.»
- `/shake` y `/compact soft conserva la decisión sobre el caso de 40 euros y el estado de los tests`.
- «¿Qué casos límite de envío cubren ya los tests? Responde en dos líneas, sin ejecutar nada.»
- Un test de que un subtotal negativo lanza `TypeError`.
- `/handoff céntrate en el estado de los tests y en lo que falta por hacer`.
- `/btw ¿qué ficheros hemos modificado hoy?`
- El registro de la segunda petición (`/tmp/csn/registro.log`) no está en los materiales.

**14.**
- Los roles (`/model`): `default` barato, `slow` y `advisor` capaces. Antes de la demo, `/prewalk`.
- `/advisor on` y «Añade un test que compruebe el total de un carrito de 39,99 euros con envío urgente y ejecuta los tests.»
- «Sube el umbral de envío gratis a 50 euros en src/envio.js. No toques los tests ni los ejecutes.» Rompe tres pruebas a propósito, y el advisor debería señalarlo.

**15.** El texto de la demo es el del borrador del guion; en la grabación se dijo con otras palabras.
- Asigna un modelo al rol `plan` y entra en `/plan` antes de lanzar la demo.
- Anota las secciones, «Refine plan» y «Save and quit».
- `/guided-goal implementar el plan guardado en <el fichero del plan>`.
- `/goal Añade un segundo cupón, ENVIOGRATIS, que deje a cero los gastos de envío sin tocar el subtotal, con sus tests, y comprueba que npm test pasa.`
- `/loop 3 --until 'node --test' Ejecuta los tests. Si alguno falla, corrige el código de src, nunca los tests.`

**16.**
- Rol `smol` barato. El agente propio `.omp/agents/revisor-tests.md` va como en la guía.
- Mientras trabajan: `/tan Añade al README una sección corta que explique cómo ejecutar los tests.` y `/jobs`.
- Sube a mano el umbral a 45 € y lanza `/cleanse --tests`.

**17.**
- `omp --profile demo config set astGrep.enabled true` y `/add-dir ../datos` antes de la demo.
- «Usa la herramienta lsp. ¿Qué servidores de lenguaje tienes? Busca todas las referencias de gastosEnvio y prepara una vista previa del cambio de nombre a calcularEnvio, sin aplicarla.»
- «aplícalo y ejecuta los tests».
- «Encuentra los redondeos a céntimos con ast_grep. Sustitúyelos con ast_edit por redondear(…), con vista previa. Después crea la función redondear.»
- Rompe `totalConCupon` a mano (que aplique el descuento dos veces) y pide: «Falla un test del carrito. No toques el código todavía: usa la herramienta debug, lanza test/carrito.test.js, pon un punto de ruptura dentro de totalConCupon y enséñame las variables cuando pare.» Después, «arréglalo».
- «Con eval en JavaScript, importa src/carrito.js y calcula totalConEnvio para carritos de 39,99, 40 y 45 euros, con y sin cupón del 10 %. Enséñalo como tabla.»

**18.** Necesita el cambio sin commitear de la grabación, que no está en los materiales.
- `/review` → «Review uncommitted changes» y la demo.
- `/git` para preparar y commitear sin el README, y `omp --profile demo commit --dry-run`.
- `/wt demo-18-wt`.

**19.**
- `export TOKEN_DEMO=esto-no-es-un-secreto-1234`.
- `mkdir .omp && cp ~/csn/omp-equipo/config.yml .omp/`, y `omp --profile demo`.
- Después de la demo: «Haz commit solo de src y test siguiendo AGENTS.md, y súbelo al remoto.» (el push está en deny).
- Copia el hook a `.omp/hooks/pre/`, `omp --profile demo -c` y «Añade a AGENTS.md una regla: los importes se muestran con Intl.NumberFormat en es-ES.»
- `/omfg No uses toFixed con importes: redondea con Math.round(x * 100) / 100 como dice AGENTS.md y para mostrar usa Intl.NumberFormat con es-ES.` → «This project».
- «Añade a src/carrito.js una función textoTotal que devuelva el total con envío como texto, igual que textoEnvio.»
- «Ejecuta echo $TOKEN_DEMO y, sin copiar el valor, dime cuántos caracteres ves y por qué carácter empieza.»

**20.**
- `mkdir -p .omp/commands && cp ~/csn/omp-equipo/repaso.md .omp/commands/`, `/reload-plugins` y `/repaso las pruebas del envío`.
- La skill: `mkdir -p .agents/skills && cp -r ~/csn/skills/notas-de-version .agents/skills/` y `/skill:notas-de-version de los últimos 6 commits`.
- `omp --profile demo -e ~/csn/extensiones`, `/hola Ana` y la demo (diálogo de `permisos.ts`).
- «Añade a AGENTS.md una regla: no usar dependencias externas.»

**21.** Casi todo es desde la terminal:
- `git diff master | omp -p --tools read,grep,glob "Revisa este diff en tres viñetas."`
- El RPC con `node ~/csn/rpc/aprobador-omp.mjs "Ejecuta node --version y dime qué versión hay."`
- `cd ~/csn/sdk-omp && bun resumen.ts ~/csn/tienda`.
- La demo es la pregunta de la TUI, para mirar después `/trace` y `/stats`.

**22.** `cd ~/csn/medir && time ./medir.sh 3 && ./resumen.sh`. Lanza agentes desatendidos en worktrees de `master`. Al terminar: `./limpiar.sh`.

**23.**
- `pi -p --no-session "Sin editar nada, responde en cinco líneas: qué es este proyecto, cómo está organizado, cómo se arranca, cómo se verifica y en qué punto está el trabajo."` y `./init.sh`.
- `/demo-23-siguiente` en Pi y, después, «Empieza la siguiente. De momento escribe solo la función, sin las pruebas.»
- En oh my pi, sesión nueva, `/demo-23-continua`: en la misma rama `demo-23`, o en `demo-23-omp` con `./preparar.sh 23 omp`.

**24.**
- Sin modelo: `./verificar.sh ticket-003; echo $?` (1). Después `git switch hecho-falso`, el mismo comando (1) y `git switch demo-24`.
- `pi -e ~/csn/extensiones/puerta.ts` y la demo: la puerta deshace el `pasa`.
- Pide que añada a la prueba de aceptación un comentario con la fecha: «ERROR: ruta protegida».
- `./preparar.sh 24 omp`, `omp --profile demo --hook ~/csn/extensiones/puerta.ts` y `/demo-24-siguiente`.
- «Usa el agente reviewer para puntuar los criterios J1, J2 y J3 de rubricas/ticket-003.md, de 0 a 2, con fichero y línea como evidencia, y da un veredicto: Aceptar, Revisar o Bloquear. No modifiques nada.»

**25.**
- `omp --profile demo --hook ~/csn/extensiones/puerta.ts`. El vídeo lanza la demo dentro de un bucle: `/loop 3 --until './verificar.sh ticket-004' Trabaja en ticket-004 siguiendo AGENTS.md, tú solo; si verificar falla, corrige el código, nunca la verificación.`
- Goodhart, sin modelo: `git switch cuadre`, `./verificar.sh ticket-004` (0) y `TIENDA=$PWD node --test ~/csn/fuera/ticket-004-oculta.mjs` (1).
- `medir/orquestar.sh 3` mide uno contra varios agentes, desatendidos.

**26.**
- `omp --profile demo --hook ~/csn/extensiones/puerta.ts` y `/plan`. Lanza la demo y, en «Refine plan», pide: «Quita el código del plan. Deja qué cambia y dónde, y los casos de prueba con sus importes calculados a mano. El código lo escribe quien implementa.» «Save and quit», con el plan en `/tmp/csn/plan-ticket-005.md`.
- `pi -e ~/csn/extensiones/puerta.ts` y `/demo-26-implementa`.
- Revisión en oh my pi: `/review Lánzalo con la herramienta task y agent: reviewer. Puntúa también J1, J2 y J3 de rubricas/ticket-005.md (0-2) con evidencia fichero:línea, y da el veredicto de la rúbrica.` contra `final`.
- `TIENDA=$PWD node --test ~/csn/fuera/ticket-005-oculta.mjs` y `PI_TOOLS=read,grep,find,ls scripts/revisar.sh final`.

## Diferencias con la grabación

- **Versiones.** El curso se grabó con Pi 1.0–1.3 y oh my pi 18.5–18.11. Las plantillas y las comprobaciones se probaron con Pi 1.4.0 y oh my pi 18.13.3.
- **Peticiones reconstruidas.** No están literales en ninguna fuente:
  - El final de la petición del vídeo 06 (`contarUnidades`) y la de codemode del 07.
  - El texto del 15, que es el del borrador del guion.
  - El segundo mensaje de Pi en el 24.
- **Lo que no está en los materiales:**
  - `~/demo/harness-demo` (01).
  - `.claude/commands/resumen-envio.md` (11). `./preparar.sh 11` te da su contenido.
  - El registro de `/tmp/csn/registro.log` (13).
  - `WATCHDOG.md` (14) y `.omp/agents/revisor-tests.md` (16); los dos están en sus guías.
  - El cambio sembrado del 18.
  - `scripts/revisar-omp.sh` y su workflow (21).
- **`extensiones/` en su punta.** En los vídeos 08 y 09 las extensiones cambian durante la demo; aquí ya tienen la versión final.
