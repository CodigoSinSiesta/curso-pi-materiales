#!/usr/bin/env bash
# Una fila por ejecución de orquestar.sh y la media por condición. Tokens y coste de todos los agentes: el principal
# (message_end del flujo) y cada subagente (su <id>.jsonl en la carpeta de sesión). Uso: ./resumen-orquestar.sh
set -euo pipefail
export LC_ALL=C
cd /tmp/csn/r25
echo "en ${PWD/#"$HOME"/\~}"
printf '%-10s %5s %3s %4s %4s %8s %6s %8s  %-8s %-6s %-7s %-6s %s\n' \
  ejecución seg omp task subs tokens caché 'cent $' verificar oculta intacta válida ficheros
for c in uno varios; do
  for f in "$c"-[0-9]*.jsonl; do
    [ -e "$f" ] || continue
    r=${f%.jsonl}
    read -r seg salida tareas verificar oculta intacta commits ficheros < "$r.juez"
    hijos=$(find "$r.ses" -mindepth 2 -name '*.jsonl' | grep -v '/__' || true)
    subs=$(printf '%s' "$hijos" | grep -c . || true)
    read -r tok cache coste modelos < <(
      { jq -c 'select(.type=="message_end" and .message.role=="assistant") | .message' "$f"
        for h in $hijos; do jq -c 'select(.type=="message" and .message.role=="assistant") | .message' "$h"; done
      } | jq -s -r '(map(.usage)) as $u
          | "\($u | map(.totalTokens) | add // 0) \($u | map(.cacheRead) | add // 0)"
          + " \($u | map(.input + .cacheRead + .cacheWrite) | add // 0) \($u | map(.cost.total) | add // 0)"
          + " \(map(.provider + "/" + .model) | unique | join(","))"' | awk '{printf "%s %.1f %.4f %s\n", $1, ($3>0 ? 100*$2/$3 : 0), 100*$4, $5}')
    # Válida: uno sin task, varios con task, y todo con DeepSeek Flash (si falta la clave, omp cae a otro modelo).
    # «intacta» no invalida: si un agente toca la verificación, es un resultado (y verificar.sh lo juzga la etiqueta).
    valida=si
    { [ "$c" = uno ] && [ "$tareas" -gt 0 ]; } && valida=no
    { [ "$c" = varios ] && [ "$tareas" -eq 0 ]; } && valida=no
    [ "$modelos" = deepseek/deepseek-flash ] || valida=no
    [ "$verificar" = 0 ] && v=verde || v=rojo
    printf '%-10s %5s %3s %4s %4s %8s %5s%% %8s  %-8s %-6s %-7s %-6s %s\n' \
      "$r" "$seg" "$salida" "$tareas" "$subs" "$tok" "$cache" "$coste" "$v" "$oculta" "$intacta" "$valida" "$(tr , '\n' <<< "$ficheros" | grep -c .)"
  done
done | tee filas-orquestar.txt
echo
printf '%-8s %7s %9s %6s %9s %9s %7s %7s\n' media seg tokens caché 'cent $' verificar oculta intacta
awk '$12=="si" { c=$1; sub(/-[0-9]+$/, "", c); n[c]++; s[c]+=$2; t[c]+=$6; k[c]+=$7; d[c]+=$8
                 if ($9=="verde") v[c]++; if ($10=="pasa") o[c]++; if ($11=="si") i[c]++ }
     END { for (c in n) printf "%-8s %7.0f %9.0f %5.1f%% %9.4f %7d/%d %5d/%d %5d/%d\n",
                               c, s[c]/n[c], t[c]/n[c], k[c]/n[c], d[c]/n[c], v[c], n[c], o[c], n[c], i[c], n[c] }' filas-orquestar.txt | sort
echo "(la media solo cuenta las ejecuciones válidas; cent \$ = céntimos de dólar)"
