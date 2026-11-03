# Problemas conocidos

Lo que te puedes encontrar al seguir el curso, qué significa y cómo se arregla. Solo hay problemas que han pasado de verdad: en las grabaciones, al preparar las demos o al probar los comandos con versiones posteriores.

Los vídeos se grabaron con Pi 1.0–1.3 y oh my pi 18.5–18.11. Donde un mensaje cambia con la versión, se indica. Las filas marcadas con «Pi 1.4» u «omp 18.13» se han comprobado con esas versiones.

Si tu problema no está aquí, [abre un issue](https://github.com/CodigoSinSiesta/curso-pi-materiales/issues/new/choose). No pegues claves ni tokens.

- [Instalación](#instalación)
- [Claves y proveedores](#claves-y-proveedores)
- [Pi](#pi)
- [oh my pi](#oh-my-pi)
- [La tienda y las ramas](#la-tienda-y-las-ramas)
- [Extensiones](#extensiones)
- [CI, RPC y SDK](#ci-rpc-y-sdk)
- [Si cambia una versión](#si-cambia-una-versión)

## Instalación

| Lo que ves | Qué significa | Cómo se arregla | Vídeo |
|---|---|---|---|
| `npm install -g @earendil-works/pi-coding-agent` avisa del motor, o `pi` no arranca. | Pi necesita Node 22.19 o posterior. | Actualiza Node (`node --version`), o usa el instalador oficial, que lo trae: `curl -fsSL https://pi.dev/install.sh \| sh`. | 02 |
| `./preparar.sh` dice «Aviso: los scripts del curso esperan esta carpeta en ~/csn». | Has clonado en otra carpeta. `preparar.sh` funciona igual, pero varios scripts (`medir/`, `rpc/`, `revisar.sh`) buscan `~/csn`. | Clona en `~/csn`, o adapta las rutas de los scripts que uses. | Todos |
| No encuentras la documentación o el paquete de Pi en `$(npm root -g)`. | Tienes varios Node (un gestor de versiones y Homebrew, por ejemplo) y `npm root -g` es el de otro. | Usa el `npm` del mismo Node con el que instalaste Pi: compara `which pi` y `which npm`. | 09, 10, 24 |
| `omp --version` no es la versión que esperas, o la documentación del paquete es de otra versión. | Hay dos `omp`: el binario del instalador y un paquete global de Bun antiguo. | `which -a omp` para verlos. Quédate con uno y actualiza con `omp update`. | 11, 18 |
| `curl -fsSL https://omp.sh/install \| sh` termina con «Bun 1.4.4 or newer is required». | Si tienes Bun, el instalador instala con Bun, y tu Bun es antiguo. | `bun upgrade`, o pide el binario: `curl -fsSL https://omp.sh/install \| sh -s -- --binary`. Lo pide el instalador actual. | 11 |
| `pi mcp add …` (u otro subcomando) falla. | `pi` es un alias con opciones, como `--no-skills`, y los subcomandos no las admiten. | `command pi mcp add …`, o quita el alias. | 07 |
| Tras actualizar omp, al arrancar sale un bloque «What's New · Updated to v…» que avisa de «1 breaking change». | Es el resumen del changelog. Sale una vez por versión. | Léelo (también con `/changelog`). Si vas a grabar o compartir pantalla, arranca omp una vez antes. | 11, 26 |

## Claves y proveedores

| Lo que ves | Qué significa | Cómo se arregla | Vídeo |
|---|---|---|---|
| `pi -p …` responde «No API key found for the selected model.» | Pi no tiene credenciales para el modelo elegido. | Exporta la variable del proveedor (`export DEEPSEEK_API_KEY=…`) o entra con `/login`. Pi 1.4. | 02, 04 |
| `omp` responde «No default model selected. Use /login, set an API key environment variable…». | omp no encuentra ningún modelo con credenciales. También pasa en `--mode rpc`. | Exporta la clave, entra con `/login` o pasa `--model proveedor/modelo`. omp 18.13. | 11, 21 |
| Error 429, conexiones cortadas y, al final, «Retry failed after 3 attempts». | El modelo gratuito de OpenRouter está saturado. Pi reintenta tres veces y se rinde. | Espera y repite, o usa un modelo de pago o tu propia clave. | 02 |
| `omp --model deepseek/xxx` responde «Model "deepseek/xxx" not found». En Pi solo sale un aviso, «Using custom model id», y sigue. | El nombre del modelo no existe en el catálogo. Pi lo intenta igualmente y fallará al llamarlo. | Busca el nombre exacto: `omp models find <texto>` o `pi --list-models <texto>`. Pi 1.4, omp 18.13. | 04, 14 |
| Un modelo local tarda minutos en responder, o responde rápido pero se inventa lo que hay en los ficheros. | Un modelo de razonamiento pequeño se va en pensar; uno minúsculo no maneja bien las herramientas. | Pruébalo con una tarea de respuesta conocida. Con Ollama, `"apiKey": "ollama"` es obligatorio aunque no use clave. Con `llama-server`, arranca con `--jinja`. | 04 |
| Vuelves de un modelo local al de siempre y el pie dice `thinking off`. | El modelo local no razona y el nivel se quedó en `off`. | Súbelo con `Shift+Tab` o `/thinking`. | 04 |
| `/effort medium` responde en rojo «Unknown thinking level: medium. Available: off, auto, low, high, max». | Cada modelo admite solo algunos niveles. | Elige uno de la lista del mensaje. | 14 |
| `omp -p` responde con un modelo que no esperabas. | Sin la clave del proveedor en el entorno, omp cae a otro modelo que tengas configurado. | Exporta la clave y fija `--model` en los scripts. `medir/orquestar.sh` se niega a arrancar sin `DEEPSEEK_API_KEY` por eso. | 22, 25 |
| Dentro del contenedor de `docker/Dockerfile.pi`, Pi no tiene modelo ni sesión iniciada. | El volumen del directorio del agente empieza vacío. | Pasa la clave y el modelo: `docker run … -e DEEPSEEK_API_KEY pi-sandbox --model deepseek/deepseek-flash`. No montes tu `~/.pi/agent`. | 05 |

## Pi

| Lo que ves | Qué significa | Cómo se arregla | Vídeo |
|---|---|---|---|
| `/compact` responde en rojo «nothing to compact (session too small)». | La sesión ocupa menos que los 20 000 tokens recientes que siempre se conservan. | No es un fallo. Para forzarlo, baja `compaction.keepRecentTokens`. | 03 |
| Vuelves atrás con `/tree` y el código sigue cambiado. | El árbol mueve la conversación, no tus ficheros. | Guarda cada intento en git y restaura con `git checkout -- <fichero>`. | 03, 09 |
| En `repo-ajeno/`: «This project is not trusted…» y su extensión no carga. Pero el agente sí lee su `AGENTS.md`. | La confianza de proyecto filtra lo que se ejecuta (`.pi/`: extensiones, MCP, skills), no lo que el modelo lee. | `pi -a` o `/trust` si confías; `-na` para ignorar `.pi/`; `-nc` para no cargar `AGENTS.md` ni `CLAUDE.md`. Pi 1.4. | 05 |
| En `~/csn/tienda`, Pi tiene en el contexto también `~/csn/AGENTS.md`, el de este repositorio. | Pi carga los `AGENTS.md` de la carpeta de trabajo y de todas las superiores, aunque la tienda sea otro repositorio git. oh my pi se para en la raíz del repositorio. | Normalmente no molesta: dice que dentro de `tienda/` manda `tienda/AGENTS.md`. Si quieres el contexto exacto de la grabación, trabaja en una copia de la tienda fuera de `~/csn` (por ejemplo, un `git worktree` en `/tmp`). Pi 1.4. | 03, 05, 22 |
| Con `--tools read,grep,find,ls` el agente no escribe, pero lee `fuera/secreto.txt`. | Solo lectura no es aislamiento: puede leer cualquier fichero al que llegue tu usuario. | Para aislar, contenedor o máquina virtual. | 05 |
| En Docker, Pi descarga `fd` al arrancar y lo que escribe aparece en tu carpeta. | El contenedor tiene red y `/workspace` está montado en escritura. | Monta en solo lectura (`-v "$PWD:/workspace:ro"`) y pasa solo las variables imprescindibles. | 05 |
| Escribes mal una herramienta en `--tools` y Pi arranca sin ella, sin avisar. | Pi ignora en silencio los nombres que no existen. oh my pi, en cambio, se niega a arrancar. | Revisa el nombre. Las integradas de Pi son `read`, `bash`, `edit`, `write`, `grep`, `find` y `ls`. Pi 1.4. | 05, 10, 22 |
| `pi` responde «Error: Unknown option: --hook» (o `--max-time`, `--config`…). | Es una opción de oh my pi, no de Pi. | En Pi, las extensiones van con `-e`. El límite de tiempo, fuera (`timeout`, o `timeout-minutes` en CI). Pi 1.4. | 10, 22 |
| Con MCP, la primera respuesta tarda, o el modelo encadena varios scripts de codemode (uno con `searchTools()` sin `await`). | Los servidores en modo `direct` hacen esperar al primer mensaje; descubrir herramientas en codemode cuesta turnos. | Usa la exposición `codemode` o `deferred` y pide tareas concretas. Mira el estado con `/mcp`. | 07 |

## oh my pi

| Lo que ves | Qué significa | Cómo se arregla | Vídeo |
|---|---|---|---|
| `omp --tools read,grep,find,ls` no arranca: «Unknown tool in --tools: ls.» o «Built-in tool unavailable in this session: find.» | omp nunca tuvo `ls`, y `find` no se puede pedir: la búsqueda por nombre se llama `glob` (ya en 18.6). Un `--tools` con una herramienta que no está disponible impide arrancar. | Para solo lectura: `--tools read,grep,glob`. Revisa los scripts que traigas de Pi. omp 18.11–18.13. | 11, 21 |
| `omp` responde «Error: unknown flag: --no-approve» (o `-t`, `--no-mcp`). | Es una opción de Pi. omp no tiene confianza de proyecto ni `-t`. | `--tools` en lugar de `-t`. Para lo demás, mira `omp --help`. omp 18.13. | 11, 21 |
| En `omp -p` o en CI: «Tool "…" requires approval but no interactive UI available. Options: 1. Set tools.approvalMode: yolo…». | En modo `write` o `always-ask`, lo que necesita aprobación falla cerrado si no hay a quién preguntar. | No pongas yolo. Añade un `allow` para ese comando, o deja solo herramientas de lectura y detecta el bloqueo en los eventos. | 19, 21 |
| `git push` sale en rojo: «Tool "bash" is blocked by tool policy. Reason: Blocked by bash pattern: git push*». Y `git status && git log` pide aprobación aunque los dos estén permitidos. | Un `deny` bloquea siempre, también en yolo. Un `allow` tiene que cubrir la línea entera y nunca aprueba un comando compuesto. | Es lo que hace `omp-equipo/config.yml`. Para no ver el diálogo, separa los comandos. | 19 |
| `/plan` responde «exit goal mode first» y el menú dice «blocked by goal mode». | Plan, goal y vibe se excluyen. | Termina o pausa el objetivo antes de planificar. | 15 |
| `/compact snapcompact` responde «snapcompact would not reduce context». `/snapcompact` no existe. | Son modos de `/compact`, no comandos. Snapcompact no ahorra nada en sesiones pequeñas. | `/compact soft [foco]`, o `/shake`, que no usa el modelo. | 13 |
| La herramienta `lsp` o `debug` falla o no aparece. | omp no trae el servidor de lenguaje ni el adaptador de depuración. No existe un paquete npm `js-debug-adapter`. | Instala `typescript-language-server`. Para depurar JavaScript, instala vscode-js-debug (`dapDebugServer.js`) o apunta `JS_DEBUG_DAP_SERVER` a él. | 17 |
| `/remove-dir .` responde «cannot remove the working directory». | La carpeta de trabajo no se quita con `/remove-dir`. | Cámbiala con `/move <ruta>`. | 17 |
| `omp commit` rechaza su propio mensaje: «Summary must start with a past-tense verb». Y en `--dry-run` te ha preparado todos los ficheros. | El validador exige mensajes en inglés con verbo en pasado. Si no hay nada preparado, lo prepara todo, también en modo de prueba. | Prepara antes lo que quieras con `/git`. Si quieres tu formato, escribe tú el mensaje. | 18 |
| `/review` falla en el primer `task` (falta `context`) o lanza un subagente genérico en vez de `reviewer`. | Que reparta bien depende del modelo de la conversación. | Repite, o pide «con la herramienta task y agent: reviewer». Comprueba en el registro qué agente revisó. | 18, 26 |
| Siguen activas skills personales aunque desactives esa fuente. | `~/.agents/skills` se carga siempre, con cualquier perfil. | Míralo en `/extensions` y mueve esas skills si no las quieres. | 20 |
| El primer `bash` del agente falla con «Service mode does not accept async or timeout» y lo repite. | El modelo pidió opciones de bash que ese modo no admite. | Nada: el modelo reintenta solo. Cuesta un turno. | 23 |
| Un ajuste de `--config fichero.yml` no hace nada. | omp ignora en silencio las claves que no conoce (solo se queja si el YAML está mal escrito: «Failed to parse config overlay»). Las listas, además, se reemplazan enteras. | Comprueba la clave con `omp config get <clave>`: si no existe, responde «Unknown setting». omp 18.13. | 19, 22, 25 |

## La tienda y las ramas

| Lo que ves | Qué significa | Cómo se arregla | Vídeo |
|---|---|---|---|
| `./verificar.sh` sale con 1 y dice «ERROR: no hay ninguna etiqueta rubrica-* en la historia.» (en la rama `verificar`, «fatal: bad revision 'rubrica-ticket-003'»). | A5 compara con las etiquetas de las rúbricas y tu tienda no las tiene. Están publicadas en el repositorio desde el 3 de noviembre de 2026; un clon anterior no las trae. | `cd ~/csn && git fetch --tags && ./preparar.sh`: las lleva a la tienda (o las crea sobre los commits de la grabación, también si ya habías preparado antes. Compruébalo con `git -C ~/csn/tienda tag`. A mano: `git tag rubrica-ticket-003 3a36c10`, y lo mismo con `rubrica-ticket-004-v1 d265135`, `rubrica-ticket-004 0ad4487` y `rubrica-ticket-005 6ff1952`. | 24, 25, 26 |
| `git diff main` falla en la tienda. | La rama base de la tienda es `master`, no `main`. | `git diff master`. | 10, 21 |
| En `umbral-50` fallan 3 de 15 tests y `scripts/revisar.sh` sale con 1. | Es a propósito: la rama sube el envío gratis a 50 € sin tocar las pruebas. | Nada. Es lo que la revisión tiene que detectar. | 10 |
| `./verificar.sh ticket-005` sale con 1 en la rama `final`. | Por diseño: la funcionalidad está por hacer y su aceptación falla hasta que exista. `npm test` no la ejecuta porque vive en `aceptacion/`. | Haz la funcionalidad. La aceptación sola: `node --test aceptacion/ticket-005.mjs`. | 24, 25, 26 |
| En `hecho-falso`, `npm test` pasa 24 de 24, pero `./verificar.sh` da «el ticket termina en «Total: 45,74 €» y el total de la tienda es 50,69 €». | Es la demo: el envío se calcula sobre el subtotal antes del cupón. | El arreglo usa `totalConEnvio`, como dice el mensaje. | 24 |
| En `cuadre`, `./verificar.sh ticket-004` sale con 0, pero la prueba oculta falla. | Es la demo de Goodhart: el IVA se calcula «por diferencia» para que cuadre. | Compruébalo con `TIENDA=$PWD node --test ~/csn/fuera/ticket-004-oculta.mjs`. | 25 |
| A5 en rojo: «ERROR: la verificación ha cambiado desde rubrica-ticket-00N». | Alguien ha tocado `rubricas/`, `aceptacion/` o `verificar.sh` desde la etiqueta. | Restaura lo de la etiqueta: `git checkout rubrica-ticket-00N -- rubricas aceptacion verificar.sh`. | 24, 25 |
| `git worktree add <carpeta> master` falla. | `master` ya está sacada en `~/csn/tienda`. | `git worktree add --detach <carpeta> master`. En un script, añade `set -euo pipefail` para que un `cd` fallido no deje al agente en la tienda. | 22, 25 |
| `git request-pull final <remoto> HEAD` falla con «No match for commit … Are you sure you pushed 'HEAD' there?». | Estás en un worktree en detached HEAD. | Usa el nombre de la rama (`ticket-005`) o `HEAD:ticket-005`. | 26 |

## Extensiones

| Lo que ves | Qué significa | Cómo se arregla | Vídeo |
|---|---|---|---|
| Pi no arranca: «Error: Failed to load extension "…": …» y «Hint: Start without extensions using "pi -ne"». | Una extensión tiene un error o la ruta no existe. Pi se niega a arrancar. | Arregla la extensión o la ruta de `-e`. Para arrancar sin ellas, `pi -ne`. Pi 1.4. | 08, 09 |
| oh my pi arranca, pero tu extensión no hace nada. En la salida de error pone «Failed to load extension …». | omp sigue sin la extensión que no carga. | Mira la salida de error al arrancar y arregla la extensión. omp 18.13. | 20, 24 |
| Tras `/reload`, el pie de tu extensión desaparece o los contadores vuelven a cero. | `/reload` recrea las extensiones: se pierde lo que vivía en variables. | Guarda el estado en la sesión y reconstrúyelo en `session_start`, como `permisos.ts` y `tests.ts`. | 08, 09 |
| Tras `/tree` a un punto anterior, una acción pasa sin diálogo porque se aprobó en otra rama. | La extensión recorre todo el fichero de sesión (`getEntries()`) en vez de la rama activa. | `getBranch()`, y reconstruir también en `session_tree` (en omp, además, `session_branch`). | 09, 20 |
| Tu herramienta «falla», pero el modelo lo toma como un éxito. | Devolver un objeto, aunque diga «error», cuenta como éxito. | Lanza un error desde `execute()`, como hace `tests.ts`. | 08 |
| En `pi -p`, en modo JSON o con el SDK, `permisos.ts` lo bloquea todo: «Sin interfaz para aprobar la acción». | Sin interfaz no hay a quién preguntar y la extensión falla cerrado. En RPC sí hay diálogos. | Es lo previsto. En scripts, quita las herramientas de escritura con `--tools`, o usa RPC con un cliente que conteste (`rpc/aprobador.mjs`). | 08, 10 |
| Cargas `permisos.ts` en oh my pi y te pide permiso para `glob`. | La extensión solo conoce las herramientas de Pi. Además, omp pasa `paths` en las ediciones de varios ficheros. | Añade las herramientas de omp a la lista de lectura (`glob`, `lsp`, `ast_grep`…) y mira `path` y `paths`. | 20 |
| Una extensión cargada con `-e` o `--hook` no aparece en `/extensions` de oh my pi. | Ese panel solo enseña lo que omp descubre en sus carpetas. | Que la extensión avise al arrancar, como `puerta.ts` («puerta: activa»). | 20, 24 |
| En oh my pi no existe `/reload`, y un módulo recién activado no cambia nada («newly enabled modules… require a restart»). | Los módulos nuevos necesitan reiniciar. | `/restart`, que relanza omp con las mismas opciones y retoma la sesión. | 20 |
| Tu puerta deja pasar un marcado aunque `verificar.sh` se haya colgado. | En Pi, `pi.exec` con `timeout` devuelve código 0 y `killed: true` cuando mata el proceso. | Comprueba las dos cosas: `r.code !== 0 \|\| r.killed`, como `puerta.ts`. | 24 |

## CI, RPC y SDK

| Lo que ves | Qué significa | Cómo se arregla | Vídeo |
|---|---|---|---|
| `scripts/revisar.sh` avisa «herramientas con error o bloqueadas (errores.jsonl)» aunque Pi termine bien. | Un bloqueo de la extensión no es un error de Pi; el fichero junta bloqueos y fallos. | Mira `errores.jsonl`: dice qué herramienta y por qué. | 10, 26 |
| El informe de la revisión lleva rutas absolutas de tu máquina. | El modelo copia lo que ve, carpeta de trabajo incluida. | Revisa `informe.md` antes de publicarlo o compartirlo. | 26 |
| `omp -p` sale con 0 sin esperar a sus subagentes y el reparto con `task` queda a medias. | Con `async.enabled: true`, en modo print omp aborta los subagentes al terminar el principal. | `--config ~/csn/medir/sin-async.yml`, como `medir/orquestar.sh`. | 25 |
| Un comando del agente no tiene límite aunque pusiste `tools.maxTimeout`. | Si el modelo pide `timeout: 0`, el tope no se aplica. | Pon el límite fuera del modelo: `--max-time` en omp o `timeout-minutes` en el CI. | 22 |
| `node resumen.ts` (en `sdk/`) falla con `import` o `await`, o el agente no tiene codemode ni MCP. | Hace falta ESM (`"type": "module"`) y Node 22.18 o posterior para ejecutar TypeScript sin compilar. El SDK no carga las extensiones integradas. | Usa el `package.json` de `sdk/`. Si quieres codemode o MCP, añade sus extensiones al `DefaultResourceLoader`. | 10 |

## Si cambia una versión

Cada semana, el workflow [«Pi y oh my pi al día»](.github/workflows/agentes.yml) instala la última versión de Pi y de oh my pi y comprueba, sin modelo ni clave, que los comandos del curso siguen funcionando. Si falla, cada error empieza por «Se ha roto:» y dice qué comando y de qué vídeo. Es la primera pista de que una fila nueva tiene que entrar aquí.
