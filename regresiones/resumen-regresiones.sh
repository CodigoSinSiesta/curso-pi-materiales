#!/usr/bin/env bash
# Una fila por ejecución y, por caso y tanda, si pasó alguna vez y si pasó todas. Las ejecuciones que fallan por
# infraestructura (el proveedor no respondió) se cuentan aparte y no entran en la cuenta.
# Uso: ./resumen-regresiones.sh [tanda…]      (por defecto, todas)
#   UMBRAL=0.67  fracción mínima de ejecuciones que pasan por caso; sale con 1 si algún caso queda por debajo.
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/resultados"
filtro=${*:-[a-z-]+}
printf '%-24s %-14s %-6s %4s %8s %7s  %-24s %s\n' caso ejecución estado seg tokens 'cent $' modelo comprobaciones
for r in */*-[0-9]*/; do
  r=${r%/}; caso=${r%%/*}; e=${r#*/}
  grep -qE "^($(tr ' ' '|' <<< "$filtro"))-[0-9]+$" <<< "$e" || continue
  read -r tok coste modelos ultima < <(jq -s -r '[.[] | select(.type=="message_end" and .message.role=="assistant") | .message]
    | "\(map(.usage.totalTokens) | add // 0) \(map(.usage.cost.total) | add // 0 | . * 10000 | round / 100)"
      + " \(map(.provider + "/" + .model) | unique | join(",") | if . == "" then "-" else . end) \(last.stopReason // "ninguna")"' "$r/eventos.jsonl")
  # Infraestructura: el proveedor no contestó (error, o ni un token en la última petición antes del tope).
  mudo=$(jq -s '(map(.type == "message_start" and .message.role == "assistant") | rindex(true)) as $i
    | if $i == null then 0 else (.[$i:] | map(select(.type == "message_update")) | length) end' "$r/eventos.jsonl")
  if [ "$ultima" = ninguna ] || [ "$ultima" = error ] || { [ "$ultima" = aborted ] && [ "$mudo" = 0 ]; }; then estado=infra
  elif grep -q ' falla$' "$r/comprobaciones.txt"; then estado=falla
  else estado=pasa; fi
  printf '%-24s %-14s %-6s %4s %8s %7s  %-24s %s\n' "$caso" "$e" "$estado" "$(cat "$r/segundos")" "$tok" "$coste" "$modelos" \
    "$(awk '{ printf "%s%s ", $1, ($2=="pasa" ? "✓" : "✗") }' "$r/comprobaciones.txt")"
done | tee /tmp/csn/filas-regresiones.txt
echo
printf '%-24s %-12s %6s %6s %12s %11s\n' caso tanda pasan infra 'pasó alguna' 'pasó todas'
awk -v umbral="${UMBRAL:-1}" '
  { t=$2; sub(/-[0-9]+$/, "", t); k=$1 " " t; if ($3=="infra") inf[k]++; else { n[k]++; if ($3=="pasa") p[k]++ } }
  END { mal=0
        for (k in n) { split(k, a, " "); f=p[k]/n[k]; if (f < umbral) mal=1
          printf "%-24s %-12s %3d/%-2d %6d %12s %11s\n", a[1], a[2], p[k], n[k], inf[k], (p[k]>0 ? "sí" : "no"), (p[k]==n[k] ? "sí" : "no") }
        exit mal }' /tmp/csn/filas-regresiones.txt
