#!/usr/bin/env bash
# Pasa una comprobación de código por sesiones ya grabadas, sin repetir ninguna ni gastar modelo. Solo sirven las que
# leen la sesión (sin-error, tope-coste), no las que miran el repositorio. Uso: ./comprobar-archivo.sh <comprobación> <caso.json> <carpeta>
set -euo pipefail
c=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp "$2" "$tmp/caso.json"; echo 0 > "$tmp/salida"
pasan=0; fallan=0
while IFS= read -r f; do
  # La sesión guarda las respuestas como «message»; la comprobación espera los eventos de omp -p («message_end»).
  jq -c 'select(.type=="message") | {type: "message_end", message}' "$f" > "$tmp/eventos.jsonl"
  if "$c" - "$tmp" 2>/dev/null; then pasan=$((pasan + 1)); else fallan=$((fallan + 1)); echo "falla: ${f/#"$HOME"/\~}"; fi
done < <(find "$3" -name '*.jsonl' -type f)
echo "$(basename "$1" .sh): $pasan sesiones pasan, $fallan fallan"
