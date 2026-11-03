#!/usr/bin/env bash
# Prepara los materiales del curso.
#
#   ./preparar.sh                Convierte tienda/ y extensiones/ en repositorios git propios, con las ramas
#                                de cada vídeo, como estaban en las grabaciones. Ejecútalo una vez, después
#                                de clonar en ~/csn.
#   ./preparar.sh NN [omp]       Deja la tienda en una rama demo-NN con el estado con que empieza la demo del
#                                vídeo NN. «omp» elige la parte de oh my pi en los vídeos 23 y 24.
#   ./preparar.sh NN --de-nuevo  Igual, pero si demo-NN ya tiene commits tuyos, la guarda con otro nombre
#                                (demo-NN-anterior-<fecha>) y empieza de cero.
#   ./preparar.sh lista          La tabla de vídeos, estados y herramientas.
#
# Nunca descarta trabajo: si la tienda tiene cambios sin commitear, se niega y te dice cómo guardarlos.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")" && pwd)"
TIENDA="$RAIZ/tienda"
EXT="$RAIZ/extensiones"

# Las etiquetas de las rúbricas que usa ./verificar.sh (vídeos 24-26). No viajan con las ramas, así que se
# crean aquí, sobre los mismos commits que en las grabaciones.
ETIQUETAS="rubrica-ticket-003:3a36c10 rubrica-ticket-004-v1:d265135 rubrica-ticket-004:0ad4487 rubrica-ticket-005:6ff1952"

# Las ramas de referencia y su commit. No se tocan nunca; solo se avisa si han cambiado.
REFERENCIAS="master:f27bfae iva-antes:6027f5b iva-despues:c8aba9e umbral-50:8136ca8 andamiaje:ddcd483
verificar:a0751bb hecho-falso:637b94d puerta-prueba:648d709 orquestar:0ad4487 cuadre:3f69f1d bucle-25:064a256
final:6ff1952 ticket-005:afc315d"

# vídeo|parte|commit de partida|herramienta|título|demo
TABLA='01||-|pi y omp|Qué es un harness|-
02||49c2584|pi|Instalar Pi y primera tarea|/demo-02-primera-tarea
03||eed1dbe|pi|Pi por dentro|/demo-03-iva
04||c8aba9e|pi|Modelos y proveedores|/demo-04-modelos
05||5edc6ca|pi|Seguridad y aislamiento|/demo-05-secreto
06||43bbc48|pi|Personalizar sin código|/demo-06-contar-unidades
07||8c41a07|pi|MCP y codemode|/demo-07-mcp
08||8c41a07|pi|Extensiones I|/demo-08-extensiones
09||8c41a07|pi|Extensiones II y paquetes|/demo-09-paquete
10||8136ca8|pi|Pi programático|/demo-10-revision
11||f27bfae|omp|De Pi a oh my pi|/demo-11-primer-vistazo
12||f27bfae|omp|La TUI y las sesiones|/demo-12-sesiones
13||f27bfae|omp|Contexto y memoria|/demo-13-contexto
14||f27bfae|omp|Modelos, roles y razonamiento|/demo-14-urgente
15||f27bfae|omp|Planificar y dirigir|/demo-15-cupones
16||f27bfae|omp|Subagentes y paralelo|/demo-16-subagentes
17||f27bfae|omp|El IDE integrado|/demo-17-ide
18||f27bfae|omp|Git, calidad y entrega|/demo-18-entrega
19||f27bfae|omp|Aprobaciones, reglas y hooks|/demo-19-reglas
20||f27bfae|pi y omp|Extender oh my pi|/demo-20-extender
21||8136ca8|omp|omp programático, métricas y equipo|/demo-21-programatico
22||f27bfae|pi y omp|Diseñar tu harness|-
23||35e712c|pi|El repo como sistema de registro|/demo-23-siguiente
23|omp|221f05a|omp|El repo como sistema de registro|/demo-23-continua
24||0ae405a|pi|Verificar de verdad|/demo-24-marcar-pasa
24|omp|7be4971|omp|Verificar de verdad|/demo-24-siguiente
25||0ad4487|omp|Bucles, grafos y el coste de orquestar|/demo-25-bucle
26||6ff1952|pi y omp|Proyecto final|/demo-26-plan (omp) y /demo-26-implementa (pi)'

notas() {
  case "$1" in
    01) echo "La demo usa ~/demo/harness-demo, un repositorio de tres ficheros que no está en estos materiales.
Mira la guía del vídeo 01: el ejercicio es analizar una tarea tuya con las cinco piezas del harness." ;;
    02) echo "En el vídeo, Pi arranca con un directorio de agente aparte: export PI_CODING_AGENT_DIR=/tmp/csn/pi-agent" ;;
    03) echo "En el vídeo se crean las ramas iva-antes e iva-despues. Ya existen en la tienda (son la referencia):
si repites esos git switch -c, usa otros nombres, por ejemplo iva-antes-mia e iva-despues-mia." ;;
    04) echo "Necesitas al menos un proveedor con /login o con su variable de entorno; los modelos locales son opcionales." ;;
    05) echo "fuera/secreto.txt es un token FALSO y repo-ajeno/ tiene una instrucción oculta inofensiva.
El contenedor se construye con docker/Dockerfile.pi. Si creas prueba.txt en la tienda, bórralo al terminar." ;;
    06) echo "La skill de las notas de versión está en $RAIZ/skills/notas-de-version (pi --skill <esa carpeta>)." ;;
    07) echo "pi mcp add descarga con npx el servidor de ficheros de npm. Al terminar: pi mcp remove tienda-fs" ;;
    08) echo "Las extensiones están en $EXT. La punta de permisos.ts ya trae las rutas protegidas;
en el vídeo llegan en el paso 5 (git -C \"$EXT\" show e57ec0e)." ;;
    09) echo "Las versiones de permisos.ts del vídeo: git -C \"$EXT\" show 2c76f1b:permisos.ts (la rota)
y 3667a34 (la arreglada). La punta del repositorio ya es la buena, con package.json." ;;
    10) echo "demo-10 trae el cambio que se revisa (envío gratis desde 50 €, el de umbral-50): git diff master.
Para el aprobador por RPC del final, vuelve a master: git switch master" ;;
    11) echo "El vídeo usa un comando de Claude Code del proyecto, que no está en los materiales. Si quieres verlo,
crea .claude/commands/resumen-envio.md con esto:
  ---
  description: Resume las reglas de envío
  ---
  Lee src/envio.js y resume en tres viñetas las reglas de envío. No edites nada.
Bórralo al terminar (rm -r .claude) o ./preparar.sh se negará la próxima vez." ;;
    13) echo "El registro /tmp/csn/registro.log del vídeo (2000 líneas, 14 «ERROR envio») no está en los materiales." ;;
    14) echo "El WATCHDOG.md del advisor: el texto está en la guía del vídeo 14 (va en el directorio del perfil)." ;;
    16) echo "El agente propio .omp/agents/revisor-tests.md: el frontmatter está en la guía del vídeo 16." ;;
    17) echo "Antes: omp --profile demo config set astGrep.enabled true. Los datos de solo lectura están en
$RAIZ/datos (en la TUI: /add-dir ../datos)." ;;
    18) echo "El cambio sin commitear con el fallo sembrado (envío urgente) no está en los materiales; la guía del
vídeo 18 tiene los fragmentos. El vídeo trabaja en una rama de usar y tirar: esta demo-18 lo es." ;;
    19) echo "Antes de arrancar omp: export TOKEN_DEMO=esto-no-es-un-secreto-1234 (falso).
La configuración de equipo y el hook están en $RAIZ/omp-equipo." ;;
    20) echo "Como en el vídeo, src/envio.js queda modificado sin commitear (envío gratis desde 50 €).
El comando /repaso y la skill: $RAIZ/omp-equipo/repaso.md y $RAIZ/skills/notas-de-version." ;;
    21) echo "demo-21 trae el cambio que se revisa (el de umbral-50). scripts/revisar-omp.sh y su workflow no están en los materiales." ;;
    22) echo "No hay petición interactiva: medir/medir.sh lanza la tarea en worktrees de master (/tmp/csn/r) y
medir/resumen.sh la juzga. Los scripts de medir/ esperan la carpeta en ~/csn." ;;
    23) echo "Pi trabaja la siguiente funcionalidad; omp continúa en otra sesión: ./preparar.sh 23 omp deja el estado que dejó Pi." ;;
    24) echo "Pi con la puerta: pi -e \"$EXT/puerta.ts\". Para mirar el «hecho» falso sin modelo: git switch hecho-falso.
La parte de oh my pi parte de otro commit: ./preparar.sh 24 omp, y omp --hook \"$EXT/puerta.ts\"." ;;
    25) echo "omp --hook \"$EXT/puerta.ts\". Goodhart, sin modelo: git switch cuadre y la prueba oculta de $RAIZ/fuera.
medir/orquestar.sh lanza agentes desatendidos y necesita las etiquetas rubrica-*." ;;
    26) echo "Primero el plan con omp (/plan; se guarda fuera del repositorio), después la implementación con Pi:
pi -e \"$EXT/puerta.ts\". El vídeo usa un remoto bare local para la petición de cambios; no hace falta." ;;
  esac
}

aviso_omp() {
  case "$1" in 1[1-9]|2[0-6]) echo "oh my pi: el perfil viene en modo yolo (edita y ejecuta sin preguntar). Trabaja solo en esta carpeta." ;; esac
}

asegurar_etiquetas() {
  local par nombre sha actual
  for par in $ETIQUETAS; do
    nombre=${par%%:*}; sha=${par#*:}
    if actual=$(git -C "$TIENDA" rev-parse -q --verify "refs/tags/$nombre^{commit}" 2>/dev/null); then
      [ "${actual:0:7}" = "$sha" ] || echo "Aviso: la etiqueta $nombre apunta a ${actual:0:7}, no a $sha como en las grabaciones."
    elif git -C "$TIENDA" cat-file -e "$sha^{commit}" 2>/dev/null; then
      git -C "$TIENDA" tag "$nombre" "$sha" && echo "tienda: etiqueta $nombre → $sha"
    else
      echo "Aviso: no encuentro el commit $sha para la etiqueta $nombre."
    fi
  done
}

avisar_referencias() {
  local par rama sha actual
  for par in $REFERENCIAS; do
    rama=${par%%:*}; sha=${par#*:}
    actual=$(git -C "$TIENDA" rev-parse -q --verify "refs/heads/$rama" 2>/dev/null) || continue
    [ "${actual:0:7}" = "$sha" ] || echo "Aviso: la rama $rama ya no está en $sha (ahora ${actual:0:7}). Las demos que comparan con ella verán otra cosa."
  done
}

lista() {
  printf '%-7s %-8s %-9s %-26s %s\n' "Vídeo" "Commit" "Herram." "Demo" "Título"
  while IFS='|' read -r v parte sha herr titulo demo; do
    printf '%-7s %-8s %-9s %-26s %s\n' "$v${parte:+ $parte}" "$sha" "$herr" "${demo%% *}" "$titulo"
  done <<< "$TABLA"
}

preparar_todo() {
  cd "$RAIZ"
  [ "$RAIZ" = "$HOME/csn" ] || echo "Aviso: los scripts del curso esperan esta carpeta en ~/csn (está en $RAIZ)."
  git fetch -q origin '+refs/heads/tienda/*:refs/heads/tienda/*' '+refs/heads/extensiones/*:refs/heads/extensiones/*' 2>/dev/null || true
  for repo in tienda extensiones; do
    if [ -d "$repo/.git" ]; then echo "$repo ya es un repositorio: no lo toco"; continue; fi
    rama=$([ "$repo" = tienda ] && echo final || echo master)
    rm -rf "$repo"
    git init -q -b "$rama" "$repo"
    git -C "$repo" fetch -q --update-head-ok "$RAIZ" "refs/heads/$repo/*:refs/heads/*"
    git -C "$repo" checkout -q -f "$rama"
    echo "$repo: $(git -C "$repo" branch --format='%(refname:short)' | tr '\n' ' ')"
  done
  asegurar_etiquetas
  # tienda/ y extensiones/ pasan a ser repositorios propios: que el repositorio de materiales no los vea como cambios.
  git update-index --skip-worktree $(git ls-files tienda extensiones) 2>/dev/null || true
  echo "Listo. Empieza por: cd ~/csn/tienda && npm test"
  echo "Para dejar la tienda como al empezar un vídeo: ./preparar.sh NN (los vídeos: ./preparar.sh lista)"
}

preparar_video() {
  local v=$1 parte=$2 de_nuevo=$3 fila sha herr titulo demo rama sucio actual guardada n
  fila=$(grep "^$v|$parte|" <<< "$TABLA" || true)
  if [ -z "$fila" ]; then
    echo "No conozco el vídeo «$v${parte:+ $parte}». Los que hay: ./preparar.sh lista" >&2; exit 2
  fi
  IFS='|' read -r _ _ sha herr titulo demo <<< "$fila"
  echo "Vídeo $v · $titulo ($herr)"
  if [ "$sha" = "-" ]; then
    n=$(notas "$v"); [ -z "$n" ] || echo "$n"
    echo "Este vídeo no tiene demo sobre la tienda: no cambio nada."; exit 0
  fi

  if [ ! -d "$TIENDA/.git" ]; then
    echo "ERROR: $TIENDA todavía no es un repositorio git." >&2
    echo "CÓMO: ejecuta primero ./preparar.sh sin argumentos (una sola vez)." >&2; exit 1
  fi
  asegurar_etiquetas

  if [ -d "$TIENDA/.git/rebase-merge" ] || [ -d "$TIENDA/.git/rebase-apply" ] || [ -f "$TIENDA/.git/MERGE_HEAD" ]; then
    echo "ERROR: la tienda está a mitad de un rebase o un merge." >&2
    echo "CÓMO: termínalo, o abórtalo con git rebase --abort o git merge --abort, y vuelve a ejecutar esto." >&2; exit 1
  fi
  sucio=$(git -C "$TIENDA" status --porcelain)
  if [ -n "$sucio" ]; then
    echo "ERROR: la tienda tiene cambios sin commitear o ficheros nuevos, y no los voy a tocar:" >&2
    echo "$sucio" | sed 's/^/    /' >&2
    echo "CÓMO: guárdalos en un stash con nombre y vuelve a ejecutar esto:" >&2
    echo "    git -C \"$TIENDA\" stash push -u -m \"csn: antes de la demo $v\"" >&2
    echo "  Los recuperas cuando quieras con git stash list y git stash pop." >&2
    echo "  Si no los quieres, descártalos tú: git restore . y git clean (mira antes con git clean -n)." >&2
    exit 1
  fi
  if ! git -C "$TIENDA" cat-file -e "$sha^{commit}" 2>/dev/null; then
    echo "ERROR: no encuentro el commit $sha en la tienda." >&2
    echo "CÓMO: la tienda tiene que venir de estos materiales (./preparar.sh sin argumentos)." >&2; exit 1
  fi

  rama="demo-$v${parte:+-$parte}"
  if actual=$(git -C "$TIENDA" rev-parse -q --verify "refs/heads/$rama" 2>/dev/null) && [ "${actual:0:7}" != "$sha" ]; then
    if [ "$de_nuevo" = 1 ]; then
      guardada="$rama-anterior-$(date +%Y%m%d-%H%M%S)"
      [ "$(git -C "$TIENDA" branch --show-current)" != "$rama" ] || git -C "$TIENDA" switch -q --detach
      git -C "$TIENDA" branch -m "$rama" "$guardada"
      echo "Tu rama $rama anterior queda guardada como $guardada."
    else
      echo "ERROR: la rama $rama ya existe y no está en el estado inicial ($sha). Tiene esto:" >&2
      git -C "$TIENDA" log --oneline -5 "$sha..$rama" | sed 's/^/    /' >&2
      echo "CÓMO: para seguir con ella: git -C \"$TIENDA\" switch $rama" >&2
      echo "  Para empezar de cero (tu rama se guarda con otro nombre): ./preparar.sh $v${parte:+ $parte} --de-nuevo" >&2
      exit 1
    fi
  fi
  git -C "$TIENDA" switch -q -C "$rama" "$sha"

  # Estado sin commitear que forma parte de la demo.
  case "$v" in
    20) git -C "$TIENDA" restore --source=8136ca8 --worktree -- src/envio.js ;;
  esac

  avisar_referencias
  if [ -d "$EXT/.git" ] && [ -n "$(git -C "$EXT" status --porcelain)" ]; then
    echo "Aviso: $EXT tiene cambios sin commitear; las demos con extensiones usarán tu versión."
  fi
  echo "tienda: rama $rama en $(git -C "$TIENDA" log -1 --format='%h %s')"
  if (cd "$TIENDA" && npm test --silent > /dev/null 2>&1); then echo "npm test: pasa"
  else case "$v" in
    10|20|21) echo "npm test: falla, y es lo esperado: el umbral de 50 € rompe tres pruebas (es el cambio que se revisa)" ;;
    *) echo "npm test: falla. No debería al empezar esta demo: mira la salida con npm test" ;;
  esac; fi
  aviso_omp "$v"
  n=$(notas "$v"); [ -z "$n" ] || { echo; echo "$n"; }
  echo
  echo "Ahora: cd \"$TIENDA\" y lanza la demo con $demo"
  echo "Al terminar: ./comprobar.sh $v${parte:+ $parte}"
}

case "${1:-}" in
  "") preparar_todo ;;
  lista|--lista) lista ;;
  -h|--help|ayuda) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)
    v=$1; shift
    [[ "$v" =~ ^[0-9]{1,2}$ ]] || { echo "Uso: ./preparar.sh [NN [omp] [--de-nuevo] | lista]" >&2; exit 2; }
    v=$(printf '%02d' "$((10#$v))")
    parte=""; de_nuevo=0
    for a in "$@"; do
      case "$a" in
        omp) parte=omp ;;
        --de-nuevo|-f) de_nuevo=1 ;;
        *) echo "No entiendo «$a». Uso: ./preparar.sh NN [omp] [--de-nuevo]" >&2; exit 2 ;;
      esac
    done
    preparar_video "$v" "$parte" "$de_nuevo" ;;
esac
