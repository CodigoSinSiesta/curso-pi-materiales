#!/usr/bin/env bash
# Repite un caso n veces desde cero: worktree en el commit de partida, la misma orden y las mismas opciones.
# Cada ejecución deja en resultados/<caso>/<tanda>-<i>/ su manifiesto, los eventos, la sesión, la respuesta y las
# comprobaciones. Uso: ./reproducir.sh <caso.json> <repeticiones>
#   MODELO=<proveedor/modelo>  cambia solo el modelo          (tanda «otro-modelo»)
#   ARREGLO=<fichero>          lo añade al system prompt       (tanda «arreglo»)
#   TANDA=<nombre>             nombre de la tanda; por defecto «control»
set -euo pipefail
export OMP_PROFILE=demo PI_CODING_AGENT_DIR=${PI_CODING_AGENT_DIR:-/tmp/csn/pi-agent}
: "${DEEPSEEK_API_KEY:?falta la clave de DeepSeek: sin ella omp usaría otro modelo}"
aqui=$(cd "$(dirname "$0")" && pwd)
caso=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
id=$(jq -r .id "$caso"); partida=$(jq -r .partida "$caso"); contra=$(jq -r '.diff_contra // empty' "$caso")
modelo=${MODELO:-$(jq -r .modelo "$caso")}
tanda=${TANDA:-control}; [ -n "${MODELO:-}" ] && tanda=${TANDA:-otro-modelo}; [ -n "${ARREGLO:-}" ] && tanda=${TANDA:-arreglo}
read -r -a opciones <<< "$(jq -r '.opciones | join(" ")' "$caso" | sed "s|~/|$HOME/|g")"
[ -n "${ARREGLO:-}" ] && opciones+=(--append-system-prompt "$(cd "$(dirname "$ARREGLO")" && pwd)/$(basename "$ARREGLO")")
tienda=~/csn/tienda

for i in $(seq 1 "$2"); do
  r=$aqui/resultados/$id/$tanda-$i; w=/tmp/csn/r27/$id-$tanda-$i
  rm -rf "$r"; mkdir -p "$r"; cp "$caso" "$r/caso.json"
  git -C "$tienda" worktree remove --force "$w" 2>/dev/null || true
  git -C "$tienda" worktree add -q --detach "$w" "$partida"
  orden=$(cat "$aqui/$(jq -r .orden "$caso")")
  # Una revisión recibe el diff dentro de la orden, como lo recibió en su día.
  [ -n "$contra" ] && orden="$orden"$'\n\n<diff>\n'"$(git -C "$w" diff "$contra...HEAD")"$'\n</diff>'
  # Lo que la sesión no guarda: desde qué commit, con qué orden y opciones, y con qué versión del harness.
  jq -n --arg commit "$(git -C "$w" rev-parse HEAD)" --arg partida "$partida" \
        --arg modelo "$modelo" --arg harness "$(omp --version)" --arg fecha "$(date -u +%FT%TZ)" \
        --arg orden_sha "$(printf '%s' "$orden" | shasum -a 256 | cut -c1-12)" --arg tanda "$tanda" \
        --arg arreglo "${ARREGLO:-}" --args '{$commit, $partida, $modelo, $harness, $fecha, $tanda, $orden_sha,
          $arreglo, opciones: $ARGS.positional}' -- "${opciones[@]}" > "$r/manifiesto.json"

  inicio=$(date +%s)
  (cd "$w" && omp -p --mode json --no-title --model "$modelo" "${opciones[@]}" --session-dir "$r/sesion" \
     --max-time "$(jq -r .tope.segundos "$caso")" --max-cost "$(jq -r .tope.dolares "$caso")" "$orden") \
     > "$r/eventos.jsonl" 2> "$r/err" && echo 0 > "$r/salida" || echo $? > "$r/salida"
  echo $(( $(date +%s) - inicio )) > "$r/segundos"
  jq -r 'select(.type=="message_end" and .message.role=="assistant") | .message.content[]? | select(.type=="text") | .text' \
    "$r/eventos.jsonl" > "$r/respuesta.md"

  # Las comprobaciones, de la más barata a la más cara. Una línea por comprobación: nombre y pasa/falla.
  : > "$r/comprobaciones.txt"
  for c in $(jq -r '.comprobaciones[]' "$caso"); do
    "$aqui/comprobaciones/$c.sh" "$w" "$r" 2>> "$r/err" && v=pasa || v=falla
    echo "$c $v" >> "$r/comprobaciones.txt"
  done
  echo "$id $tanda-$i: $(paste -sd' ' "$r/comprobaciones.txt" | sed -E 's/ (pasa|falla)/=\1/g')"
done
