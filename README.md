# Materiales del curso «Pi y oh my pi»

Los ficheros que se usan en los vídeos del curso de [Código Sin Siesta](https://codigosinsiesta.com/rutas/pi-oh-my-pi), tal como estaban en las grabaciones: la tienda de juguete, las extensiones, los scripts de medida y las prácticas.

## Cómo empezar

Los scripts esperan esta carpeta en `~/csn`, como en los vídeos.

```bash
git clone https://github.com/CodigoSinSiesta/curso-pi-materiales.git ~/csn
cd ~/csn && ./preparar.sh
cd tienda && npm test
```

`preparar.sh` convierte `tienda/` y `extensiones/` en repositorios git propios, con las ramas de cada vídeo. Ejecútalo una sola vez.

Necesitas Node 22 o posterior, git, [Pi](https://github.com/earendil-works/pi) y, desde el vídeo 11, [oh my pi](https://github.com/can1357/oh-my-pi). Las claves de API van en variables de entorno o en `/login`; nunca en estos ficheros.

## Qué hay en cada carpeta

| Carpeta | Qué es | Vídeos |
|---|---|---|
| `tienda/` | El repositorio de juguete: carrito, envío y ticket, con sus tests. Lo usan casi todas las demos. | 01–26 |
| `extensiones/` | `hola.ts` (un comando), `tests.ts` (una herramienta), `permisos.ts` (un modo de aprobación) y `puerta.ts` (solo deja terminar si `./verificar.sh` pasa). Es también un paquete de Pi (`package.json`). | 08, 09, 20, 24 |
| `tienda/scripts/revisar.sh`, `tienda/ci/permisos.ts`, `tienda/.github/workflows/revision-pi.yml` | La revisión automática con Pi en CI: tests aparte, diff a Pi en modo JSON con herramientas de solo lectura. | 10 |
| `sdk/`, `sdk-omp/` | `resumen.ts`: Pi y oh my pi usados como librería. | 10, 21 |
| `rpc/` | `aprobador.mjs` y `aprobador-omp.mjs`: otro programa aprueba las herramientas del agente por RPC. | 10, 21 |
| `docker/Dockerfile.pi` | Pi entero dentro de un contenedor (el de `containerization.md`, con la versión fijada). | 05 |
| `fuera/` | Lo que queda fuera del proyecto: `secreto.txt` (un token **falso**) y las pruebas ocultas de aceptación de los tickets 004 y 005. | 05, 24, 25 |
| `repo-ajeno/` | Un repositorio «de otro» con una instrucción oculta inofensiva en `AGENTS.md` y una extensión que solo muestra un aviso. Sirve para practicar la confianza de proyecto. | 05 |
| `skills/notas-de-version/` | Una skill de ejemplo. | 06, 20 |
| `datos/` | Datos de solo lectura (`pedidos.db`, `tarifas-envio.pdf`) que las reglas protegen. | 17, 19 |
| `omp-equipo/` | Configuración de equipo de oh my pi y `rutas-protegidas.ts`, que traslada a omp el bloque de rutas de `permisos.ts`. | 19, 20, 21 |
| `medir/` | Medir el mismo trabajo con distintos harnesses: `medir.sh`, `prefijo.sh`, `orquestar.sh` y sus resúmenes. | 22, 25 |

## Las ramas de la tienda

Cada demo parte de un estado concreto de la tienda. Tras `preparar.sh`, están como ramas en `~/csn/tienda`:

| Rama | Qué tiene | Vídeos |
|---|---|---|
| `master` | La tienda base, con `AGENTS.md` y la revisión automática con Pi. De aquí parten la mayoría de las demos. | 03–24 |
| `iva-antes`, `iva-despues` | Las dos versiones del IVA: antes del envío o solo a los productos. | 03, 18–21 |
| `umbral-50` | El envío gratis pasa a partir de 50 €. | 10 |
| `andamiaje` | Andamiaje para sesiones largas: `init.sh`, `funcionalidades.json`, `progreso.md`, `traspaso.md`. | 23–25 |
| `verificar`, `hecho-falso`, `puerta-prueba` | `./verificar.sh` con las rúbricas, y un «hecho» que no lo es para que la puerta lo pare. | 24 |
| `orquestar`, `cuadre` | Las tareas que se miden con uno y con varios agentes. | 25 |
| `ticket-005`, `bucle-25`, `final` | El proyecto final. | 26 |

## Seguridad

- `fuera/secreto.txt` y `TOKEN_DEMO` son falsos a propósito: sirven para comprobar qué ve el agente.
- Varias demos de los vídeos 16 a 18 corren en modo yolo (sin aprobaciones). Hazlo solo en esta carpeta, nunca en un repositorio con datos reales.
- `repo-ajeno/` contiene una instrucción dirigida a asistentes de IA. Es inofensiva y está ahí para verla fallar; no la copies a otros proyectos.

## Créditos

La estructura de la tienda y varias ideas de los vídeos 22 a 25 vienen de [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) (MIT · © 2025 WalkingLab); la licencia está en `tienda/LICENSE-learn-harness-engineering`.
