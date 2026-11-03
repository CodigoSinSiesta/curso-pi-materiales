# Materiales del curso «Pi y oh my pi»

[![CI](https://github.com/CodigoSinSiesta/curso-pi-materiales/actions/workflows/ci.yml/badge.svg)](https://github.com/CodigoSinSiesta/curso-pi-materiales/actions/workflows/ci.yml) [![Pi y oh my pi al día](https://github.com/CodigoSinSiesta/curso-pi-materiales/actions/workflows/agentes.yml/badge.svg)](https://github.com/CodigoSinSiesta/curso-pi-materiales/actions/workflows/agentes.yml)

Los ficheros que se usan en los vídeos del curso de [Código Sin Siesta](https://codigosinsiesta.com/rutas/pi-oh-my-pi), tal como estaban en las grabaciones: la tienda de juguete, las extensiones, los scripts de medida y las prácticas.

## Cómo empezar

Los scripts esperan esta carpeta en `~/csn`, como en los vídeos.

```bash
git clone https://github.com/CodigoSinSiesta/curso-pi-materiales.git ~/csn
cd ~/csn && ./preparar.sh
cd tienda && npm test
```

`preparar.sh` convierte `tienda/` y `extensiones/` en repositorios git propios, con las ramas de cada vídeo. Ejecútalo una sola vez.

Necesitas Node 22.19 o posterior, git, [Pi](https://github.com/earendil-works/pi) y, desde el vídeo 11, [oh my pi](https://github.com/can1357/oh-my-pi). Las claves de API van en variables de entorno o en `/login`; nunca en estos ficheros.

Si algo no funciona, mira [PROBLEMAS.md](PROBLEMAS.md): lo que ves, qué significa y cómo se arregla, por secciones.

## Demos y comprobaciones

Para repetir una demo tal como se grabó, sin buscar el commit ni copiar el prompt:

1. `./preparar.sh NN` deja `~/csn/tienda` en una rama `demo-NN` con el estado con que empieza la demo del vídeo NN. Nunca descarta trabajo: si hay cambios sin commitear, se niega y te dice cómo guardarlos.
2. `/demo-NN-…` es una plantilla de prompt de Pi o de oh my pi que le pide al agente lo mismo que en el vídeo.
3. `./comprobar.sh NN` comprueba, sin modelo, que la práctica quedó bien hecha: qué pasa, qué falla y cómo arreglarlo. Sale con 0 si todo pasa, con 1 si algo falla y con 2 si ese vídeo se comprueba a mano (y te dice qué mirar).

```bash
cd ~/csn && ./preparar.sh 08
cd tienda && pi -e ../extensiones/tests.ts      # y en Pi: /demo-08-extensiones
cd ~/csn && ./comprobar.sh 08
```

Las plantillas se instalan una vez, enlazándolas donde las busca cada herramienta:

```bash
d="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/prompts"; mkdir -p "$d" && ln -sf ~/csn/demos/pi/*.md "$d/"
d=~/.omp/profiles/demo/agent/commands; mkdir -p "$d" && ln -sf ~/csn/demos/omp/*.md "$d/"
```

`./preparar.sh lista` enseña todos los vídeos. La tabla completa, el paso a paso de cada demo y los avisos están en [`demos/LEEME.md`](demos/LEEME.md).

## Qué hay en cada carpeta

| Carpeta | Qué es | Vídeos |
|---|---|---|
| `tienda/` | El repositorio de juguete: carrito, envío y ticket, con sus tests. Lo usan casi todas las demos. | 01–26 |
| `extensiones/` | `hola.ts` (un comando), `tests.ts` (una herramienta), `permisos.ts` (un modo de aprobación) y `puerta.ts` (solo deja terminar si `./verificar.sh` pasa). Es también un paquete de Pi (`package.json`). | 08–10, 20, 24–26 |
| `tienda/scripts/revisar.sh`, `tienda/ci/permisos.ts`, `tienda/.github/workflows/revision-pi.yml` | La revisión automática con Pi en CI: tests aparte, diff a Pi en modo JSON con herramientas de solo lectura. | 10 |
| `sdk/`, `sdk-omp/` | `resumen.ts`: Pi y oh my pi usados como librería. | 10, 21 |
| `rpc/` | `aprobador.mjs` y `aprobador-omp.mjs`: otro programa aprueba las herramientas del agente por RPC. | 10, 21 |
| `docker/Dockerfile.pi` | Pi entero dentro de un contenedor (el de `containerization.md`, con la versión fijada). | 05 |
| `fuera/` | Lo que queda fuera del proyecto: `secreto.txt` (un token **falso**) y las pruebas ocultas de aceptación de los tickets 004 y 005. | 05, 25, 26 |
| `repo-ajeno/` | Un repositorio «de otro» con una instrucción oculta inofensiva en `AGENTS.md` y una extensión que solo muestra un aviso. Sirve para practicar la confianza de proyecto. | 05 |
| `skills/notas-de-version/` | Una skill de ejemplo. | 06, 20 |
| `datos/` | Datos de solo lectura (`pedidos.db`, `tarifas-envio.pdf`) que las reglas protegen. | 17, 19 |
| `omp-equipo/` | Configuración de equipo de oh my pi y `rutas-protegidas.ts`, que traslada a omp el bloque de rutas de `permisos.ts`. | 19, 20, 21 |
| `medir/` | Medir el mismo trabajo con distintos harnesses: `medir.sh`, `prefijo.sh`, `orquestar.sh` y sus resúmenes. | 22, 25 |

## Las ramas de la tienda

Cada demo parte de un estado concreto de la tienda. Tras `preparar.sh`, están como ramas en `~/csn/tienda`:

| Rama | Qué tiene | Vídeos |
|---|---|---|
| `master` | La tienda base, con `AGENTS.md` y la revisión automática con Pi. De aquí parten las demos de oh my pi. | 10–22 |
| `iva-antes`, `iva-despues` | Las dos versiones del IVA: antes del envío o solo a los productos. | 03 |
| `umbral-50` | El envío gratis pasa a partir de 50 €, sin tocar las pruebas: fallan 3 de 15 a propósito. | 10, 20, 21 |
| `andamiaje` | Andamiaje para sesiones largas: `init.sh`, `funcionalidades.json`, `progreso.md`, `traspaso.md`. Es el final del 23. | 23 |
| `verificar`, `hecho-falso`, `puerta-prueba` | `./verificar.sh` con las rúbricas, y un «hecho» que no lo es para que la puerta lo pare (en `hecho-falso`, `./verificar.sh` falla a propósito). | 24 |
| `orquestar`, `cuadre` | Las tareas que se miden con uno y con varios agentes. En `cuadre`, la prueba oculta falla a propósito. | 25 |
| `bucle-25` | El final del 25: el desglose del pedido hecho. | 25 |
| `final`, `ticket-005` | El proyecto final: `final` lo deja por hacer y `ticket-005` lo trae hecho. | 26 |

## Seguridad

- `fuera/secreto.txt` y `TOKEN_DEMO` son falsos a propósito: sirven para comprobar qué ve el agente.
- El perfil `demo` de oh my pi está en modo yolo (sin aprobaciones) en todos los vídeos 11 a 26. Úsalo solo en esta carpeta, nunca en un repositorio con datos reales.
- `repo-ajeno/` contiene una instrucción dirigida a asistentes de IA. Es inofensiva y está ahí para verla fallar; no la copies a otros proyectos.

## Para tu agente

[AGENTS.md](AGENTS.md) explica el repositorio a Pi, a oh my pi o a cualquier agente que abras en `~/csn`: qué hay en cada carpeta, qué rama va con cada vídeo y qué no debe tocar.

## Preguntas y problemas

- Primero, [PROBLEMAS.md](PROBLEMAS.md) y la guía del vídeo en [codigosinsiesta.com](https://codigosinsiesta.com/rutas/pi-oh-my-pi).
- Si no está, [abre un issue](https://github.com/CodigoSinSiesta/curso-pi-materiales/issues/new/choose): «Duda sobre un vídeo» o «Algo no me funciona». Pide el vídeo, las versiones y la salida. Nunca pegues claves ni tokens.

## Integración continua

- [CI](.github/workflows/ci.yml), en cada push y pull request: `npm test` y `./verificar.sh` en cada rama `tienda/*` contra lo que se espera de ella (`umbral-50`, `hecho-falso` y la prueba oculta en `cuadre` fallan a propósito), y `preparar.sh` en un clon limpio.
- [Pi y oh my pi al día](.github/workflows/agentes.yml), cada lunes: instala la última versión de los dos y comprueba sin modelo ni clave que los comandos del curso siguen funcionando. Si algo se rompe, el error dice qué comando y de qué vídeo.

Los scripts de las dos están en `.github/scripts/` y funcionan también en local.

## Créditos

El código de este repositorio se publica con licencia MIT (`LICENSE`). La estructura de la tienda y varias ideas de los vídeos 22 a 25 vienen de [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) (MIT · © 2025 WalkingLab); la licencia está en `tienda/LICENSE-learn-harness-engineering`.
