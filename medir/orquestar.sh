#!/usr/bin/env bash
# La misma funcionalidad (ticket-004) con un agente y con varios. Cada ejecución en su worktree, desde la etiqueta
# de la rúbrica, y juzgada desde fuera: verificar.sh, la prueba oculta, los ficheros tocados y las llamadas a task.
# Uso: ./orquestar.sh <repeticiones> [condiciones…]   (por defecto: uno varios)
set -euo pipefail
export PI_CODING_AGENT_DIR=/tmp/csn/pi-agent OMP_PROFILE=demo
: "${DEEPSEEK_API_KEY:?falta la clave de DeepSeek: sin ella omp usaría otro modelo}"
BASE=rubrica-ticket-004
R=/tmp/csn/r25
OCULTA=~/csn/fuera/ticket-004-oculta.mjs
COMUN='Trabaja en la siguiente funcionalidad de funcionalidades.json siguiendo AGENTS.md.'
UNO='Hazlo tú solo, sin la herramienta task.'
VARIOS='Reparte con la herramienta task: un subagente implementa desglose en src/desglose.js; otro, sin ver ese fichero, escribe test/desglose.test.js a partir de funcionalidades.json y la rúbrica. Tú integras, ejecutas ./verificar.sh ticket-004, marcas y haces commit.'
# Las mismas herramientas (las de serie) y la misma puerta en las dos condiciones; solo cambia una frase.
# sin-async.yml: task espera a sus subagentes. Con async, omp -p sale en cuanto el principal termina y aborta
# a los subagentes que sigan en marcha (y sale con 0).
OMP=(omp -p --mode json --model deepseek/deepseek-flash --config ~/csn/medir/sin-async.yml
     --hook ~/csn/extensiones/puerta.ts --max-time 10m)

mkdir -p "$R"
n=$1; shift
condiciones=${*:-uno varios}
for c in $condiciones; do
  for i in $(seq 1 "$n"); do
    w=$R/$c-$i
    rm -rf "$w.ses" "$w".{jsonl,err,juez,verificar,oculta}   # restos de otra vuelta: se sumarían sus subagentes
    git -C ~/csn/tienda worktree add -q --detach "$w" "$BASE"
    cd "$w"
    [ "$c" = uno ] && frase=$UNO || frase=$VARIOS
    inicio=$(date +%s)
    "${OMP[@]}" --session-dir "$w.ses" "$COMUN $frase" > "$w.jsonl" 2> "$w.err" && salida=0 || salida=$?
    segundos=$(( $(date +%s) - inicio ))

    # Juez de fuera. Primero, qué ha tocado (también lo nuevo sin commit) y si cambió la verificación.
    git add -A
    ficheros=$(git diff --cached --name-only "$BASE" | paste -sd, -)
    git diff --cached --quiet "$BASE" -- rubricas aceptacion verificar.sh && intacta=si || intacta=no
    # Después, la verificación de la etiqueta: el juez no ejecuta lo que el agente haya podido cambiar.
    rm -rf rubricas aceptacion verificar.sh && git checkout -q "$BASE" -- rubricas aceptacion verificar.sh
    ./verificar.sh ticket-004 > "$w.verificar" && verificar=0 || verificar=$?
    TIENDA="$w" node --test "$OCULTA" > "$w.oculta" 2>&1 && oculta=pasa || oculta=falla
    tareas=$(jq -s '[.[] | select(.type=="tool_execution_start" and .toolName=="task")] | length' "$w.jsonl")
    commits=$(git rev-list --count "$BASE"..HEAD)
    echo "$segundos $salida $tareas $verificar $oculta $intacta $commits ${ficheros:--}" > "$w.juez"
    echo "$c-$i: ${segundos}s, omp sale con $salida, task $tareas, verificar.sh $verificar, oculta $oculta, en ${PWD/#"$HOME"/\~}"
    cd - > /dev/null
  done
done
