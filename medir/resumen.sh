#!/usr/bin/env bash
# Una fila por ejecución y la media por roster: llamadas por herramienta, tokens, coste y el juicio de fuera.
export LC_ALL=C
cd /tmp/csn/r
printf '%-18s %-28s %7s %8s  %-6s %s\n' ejecución herramientas tokens 'coste $' prueba ficheros
for c in pi-minimo pi-serie pi-siete omp-cuatro omp-catalogo omp-sincatalogo; do
  for f in $c-*.jsonl; do
    r=${f%.jsonl}; read -r prueba ficheros redondeo < "$r.juez"
    herr=$(jq -r 'select(.type=="tool_execution_start") | .toolName' "$f" | sort | uniq -c | awk '{printf "%s:%s ", $2, $1}')
    read -r tok coste < <(jq -s -r '[.[] | select(.type=="message_end" and .message.role=="assistant") | .message.usage]
                                    | "\(map(.totalTokens) | add) \(map(.cost.total) | add)"' "$f")
    printf '%-18s %-28s %7s %8.4f  %-6s %s\n' "$r" "$herr" "$tok" "$coste" "$prueba" "$ficheros"
  done
done | tee /tmp/csn/r/filas.txt
echo
printf '%-16s %10s %16s %9s\n' media tokens 'coste $' pasan
awk '{ c=$1; sub(/-[0-9]+$/, "", c); n[c]++; t[c]+=$(NF-3); k[c]+=$(NF-2); if ($(NF-1)=="pasa") p[c]++; if (!(c in o)) o[c]=++m }
     END { for (c in o) r[o[c]]=c
           for (i=1; i<=m; i++) { c=r[i]; printf "%-16s %10.0f %16.4f %6d/%d\n", c, t[c]/n[c], k[c]/n[c], p[c], n[c] } }' /tmp/csn/r/filas.txt
