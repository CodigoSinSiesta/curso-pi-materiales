#!/usr/bin/env bash
# El lanzador del robot: valida el encargo, prepara un worktree, lanza oh my pi con el perfil robot, lo juzga desde
# fuera y, solo si pasa, entrega la rama al repositorio de revisión con su petición de cambios.
# Uso: ./lanzar.sh <ticket-NNN|siguiente>      ./lanzar.sh --comprobar <ticket-NNN>  (lo usa el webhook: no lanza nada)
# Salida: 0 entregado · 1 verificación en rojo · 2 encargo rechazado · 3 tope de coste · 4 presupuesto agotado
#         5 ocupado · 6 infraestructura · 7 tiempo agotado
# Entorno: DEEPSEEK_API_KEY (cron no carga tu shell: cárgala antes) · ROBOT_DISPARADOR (mano, cron, webhook)
#          ROBOT_MAX_TIME (15m) · ROBOT_MAX_COST (0.10 $) · ROBOT_PRESUPUESTO_DIA (0.50 $) · ROBOT_SECO=1 (no llama al modelo)
set -uo pipefail
R=$(cd "$(dirname "$0")" && pwd); REG=$R/registro; mkdir -p "$REG"
TIENDA=~/csn/tienda; BASE=robot; REMOTO=revision; MODELO=deepseek/deepseek-flash
DISPARADOR=${ROBOT_DISPARADOR:-mano}; MAX_TIME=${ROBOT_MAX_TIME:-15m}; MAX_COST=${ROBOT_MAX_COST:-0.10}
PRESUPUESTO=${ROBOT_PRESUPUESTO_DIA:-0.50}
id=${ROBOT_ID:-$(date +%Y%m%d-%H%M%S)-$$}; inicio=$(date +%s)
CODIGOS=(entregado verificacion rechazado coste presupuesto ocupado infraestructura tiempo)

# El informe de cada ejecución, en JSON, y el código de salida con su palabra.
comprobar=no
fin() {
  local c=$1; shift
  [ "$comprobar" = si ] && { echo "$id: ${CODIGOS[$c]}${*:+ · $*}"; exit "$c"; }   # la comprobación del webhook no deja informe
  jq -n --arg id "$id" --arg disparador "$DISPARADOR" --arg ticket "${ticket:-}" --arg motivo "${CODIGOS[$c]}" \
    --argjson codigo "$c" --argjson segundos $(( $(date +%s) - inicio )) --arg detalle "$*" \
    --arg rama "${rama:-}" --arg sesion "${sesion:-}" --argjson uso "${uso:-null}" --argjson juez "${juez:-null}" \
    '{$id, $disparador, $ticket, $motivo, $codigo, $segundos, $detalle, $rama, $sesion, uso: $uso, juez: $juez}' \
    > "$REG/$id.json"
  echo "$id: ${CODIGOS[$c]}${*:+ · $*}"; exit "$c"
}

# 1. El encargo es un identificador, nunca texto: existe en la rama base y está sin empezar.
[ "${1:-}" = --comprobar ] && { comprobar=si; shift; }
ticket=${1:-}
funcs=$(git -C "$TIENDA" show "$BASE:funcionalidades.json") || fin 6 "no se puede leer $BASE"
[ "$ticket" = siguiente ] && ticket=$(jq -r '[.funcionalidades[] | select(.estado=="sin_empezar")] | sort_by(.prioridad) | .[0].id // ""' <<< "$funcs")
[[ $ticket =~ ^ticket-[0-9]{3}$ ]] || fin 2 "no es un ticket"
estado=$(jq -r --arg t "$ticket" '.funcionalidades[] | select(.id==$t) | .estado' <<< "$funcs")
[ "$estado" = sin_empezar ] || fin 2 "$ticket no está sin empezar (${estado:-no existe})"
# Idempotencia: si ya hay una rama del robot para este ticket, aquí o en el remoto, no se repite.
git -C "$TIENDA" ls-remote --exit-code --heads "$REMOTO" "robot-$ticket-*" > /dev/null && fin 2 "$ticket ya tiene rama en $REMOTO"
[ -n "$(git -C "$TIENDA" branch --list "robot-$ticket-*")" ] && fin 2 "$ticket ya tiene rama local"
# Cerrojo (macOS no trae flock): mkdir es atómico. Un encargo a la vez.
mkdir "$REG/.cerrojo" 2> /dev/null || fin 5 "hay otro encargo en marcha"
trap 'rmdir "$REG/.cerrojo"' EXIT
[ "$comprobar" = si ] && { trap - EXIT; rmdir "$REG/.cerrojo"; echo "$ticket: se puede lanzar"; exit 0; }
# Presupuesto del día: la suma de los informes de hoy.
gastado=$(cat "$REG/$(date +%Y%m%d)"-*.json 2> /dev/null | jq -s '[.[].uso.coste // 0] | add // 0')
awk -v g="$gastado" -v p="$PRESUPUESTO" 'BEGIN { exit !(g >= p) }' && fin 4 "hoy ya van $gastado \$ de $PRESUPUESTO \$"

# 2. El sitio: un worktree con una rama nueva desde la base, y el manifiesto del vídeo 27.
rama=robot-$ticket-$(date +%Y%m%d-%H%M); w=/tmp/csn/robot/$id
git -C "$TIENDA" worktree add -q -b "$rama" "$w" "$BASE" || fin 6 "no se pudo crear el worktree"
orden="Trabaja en $ticket de funcionalidades.json siguiendo AGENTS.md. Trabajas sin nadie delante: solo puedes ejecutar\
 ./init.sh, npm test, node --test, ./verificar.sh y git status, diff, log, show, add y commit, de uno en uno o unidos con &&;\
 cualquier otra orden se rechaza. Para leer ficheros usa read. Si necesitas una decisión, escríbela en traspaso.md y para."
jq -n --arg commit "$(git -C "$w" rev-parse HEAD)" --arg orden "$orden" --arg modelo "$MODELO" --arg disparador "$DISPARADOR" \
  --arg harness "$(omp --version)" --arg fecha "$(date -u +%FT%TZ)" --arg max_time "$MAX_TIME" --arg max_cost "$MAX_COST" \
  '{$commit, $orden, $modelo, $harness, $fecha, $disparador, topes: {$max_time, $max_cost}}' > "$REG/$id.manifiesto.json"
[ "${ROBOT_SECO:-}" = 1 ] && { git -C "$TIENDA" worktree remove --force "$w"; git -C "$TIENDA" branch -q -D "$rama"; rama=""; fin 2 "ensayo en seco: no se lanza el modelo"; }

# 3. El agente, con su perfil, la puerta del 24 y los topes. Sus sesiones van al perfil robot (las cuenta omp stats).
: "${DEEPSEEK_API_KEY:?falta la clave de DeepSeek: sin ella omp usaría otro modelo}"
(cd "$w" && OMP_PROFILE=robot omp -p --mode json --no-title --model "$MODELO" --hook ~/csn/extensiones/puerta.ts \
   --max-time "$MAX_TIME" --max-cost "$MAX_COST" "$orden") > "$REG/$id.jsonl" 2> "$REG/$id.err"
salida=$?
sesion=$(jq -r 'select(.type=="session") | .id' "$REG/$id.jsonl" | head -1)
uso=$(jq -s --argjson salida "$salida" '[.[] | select(.type=="message_end" and .message.role=="assistant") | .message] |
  {salida_omp: $salida, respuestas: length, tokens: (map(.usage.totalTokens) | add // 0), coste: (map(.usage.cost.total) | add // 0),
   modelos: (map(.provider + "/" + .model) | unique), ultima: (last.stopReason // null), error: (last.errorMessage // null)}' "$REG/$id.jsonl")
[ "$salida" = 3 ] && fin 3 "max-cost: $MAX_COST \$"
case $(jq -r '.error // ""' <<< "$uso") in *Deadline*) fin 7 "max-time: $MAX_TIME";; esac
[ "$(jq -r .respuestas <<< "$uso")" = 0 ] || [ "$(jq -r .ultima <<< "$uso")" = error ] && fin 6 "el proveedor no respondió"

# 4. El juez, de fuera: sin nada por commitear, verificar.sh desde la etiqueta de la rúbrica y la prueba oculta.
cd "$w"
pendiente=$(git status --porcelain | wc -l | tr -d ' ')
ficheros=$(git diff --name-only "$BASE" HEAD | paste -sd, -)
rm -rf rubricas aceptacion verificar.sh && git checkout -q "rubrica-$ticket" -- rubricas aceptacion verificar.sh
./verificar.sh "$ticket" > "$REG/$id.verificar.txt" && v=pasa || v=falla
oculta=~/csn/fuera/$ticket-oculta.mjs
if [ -f "$oculta" ]; then TIENDA="$w" node --test "$oculta" > "$REG/$id.oculta.txt" 2>&1 && o=pasa || o=falla; else o=no-hay; fi
git checkout -q HEAD -- rubricas aceptacion verificar.sh
juez=$(jq -n --arg verificar "$v" --arg oculta "$o" --argjson pendiente "$pendiente" --arg ficheros "$ficheros" \
  '{$verificar, $oculta, sin_commitear: $pendiente, ficheros: ($ficheros | split(",") | map(select(. != "")))}')
[ "$v" = pasa ] && [ "$o" != falla ] && [ "$pendiente" = 0 ] || fin 1 "la rama se queda en local: $rama"

# 5. La entrega la hace el lanzador, no el agente: push al remoto de revisión y la petición con git request-pull.
cd "$TIENDA"
git push -q "$REMOTO" "$rama" || fin 6 "no se pudo subir la rama"
git request-pull "$BASE" "$(git remote get-url "$REMOTO")" "$rama" > "$REG/$id.pr.txt" 2>&1
git worktree remove "$w"
fin 0 "$rama en $REMOTO"
