#!/usr/bin/env bash
# Busca fallos en sesiones grabadas de Pi y de oh my pi, sin llamar a ningún modelo.
# Por sesión: resultados de herramienta con error, respuestas que acabaron en error o abortadas, tokens y coste.
# Agrupa los errores por firma: herramienta + primera línea del mensaje + modelo de la sesión.
# Uso: ./minar.sh <carpeta de sesiones>…
set -euo pipefail
export LC_ALL=C
ficheros=$(find "$@" -name '*.jsonl' -type f)
echo "$(grep -c . <<< "$ficheros") sesiones en: ${*/#"$HOME"/\~}"
echo

# Una línea JSON por error, con el modelo que respondía en esa sesión.
errores=$(for f in $ficheros; do
  jq -c --arg f "$f" '
    [inputs] as $e
    | ([$e[] | select(.type=="message" and .message.role=="assistant") | .message
        | if .provider=="ollama" then "(modelo local)" else .model end] | last // "?") as $m
    | $e[] | select(.type=="message")
    | if .message.role=="toolResult" and .message.isError then
        {sesion: $f, modelo: $m, herramienta: .message.toolName,
         linea: ([.message.content[0].text // "" | split("\n")[] | sub("^\\s+"; "") | select(. != "" and . != "---")]
                 | first // "(sin texto)" | .[0:60])}
      elif .message.role=="assistant" and (.message.stopReason=="error" or .message.stopReason=="aborted") then
        {sesion: $f, modelo: $m, herramienta: "(respuesta)", linea: .message.stopReason}
      else empty end' -n "$f"
done)

echo "Firmas (veces · sesiones · herramienta · primera línea · modelo):"
jq -s -r 'group_by([.herramienta, .linea, .modelo]) | sort_by(-length)[]
  | "\(length)\t\(map(.sesion) | unique | length)\t\(.[0].herramienta)\t\(.[0].linea)\t\(.[0].modelo)"' <<< "$errores" \
  | column -t -s $'\t'
echo

echo "Las más caras (tokens · céntimos · sesión):"
for f in $ficheros; do
  jq -r --arg f "${f/#"$HOME"/\~}" -s '[.[] | select(.type=="message" and .message.role=="assistant") | .message.usage]
    | "\(map(.totalTokens) | add // 0)\t\(map(.cost.total) | add // 0 | . * 100 | . * 100 | round / 100)\t\($f)"' "$f"
done | sort -rn | head -3 | column -t -s $'\t'
