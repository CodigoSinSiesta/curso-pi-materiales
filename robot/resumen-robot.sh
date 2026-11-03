#!/usr/bin/env bash
# Lo que pasó esta noche: una fila por ejecución del robot y el gasto del día frente al presupuesto.
# Uso: ./resumen-robot.sh [AAAAMMDD]   (por defecto, hoy)
set -euo pipefail
cd "$(dirname "$0")/registro"
dia=${1:-$(date +%Y%m%d)}
ls "$dia"-*.json 2> /dev/null | grep -v manifiesto | xargs cat 2> /dev/null | jq -s -r '
  (["hora", "disparador", "ticket", "resultado", "seg", "cent $", "entregado"] | @tsv),
  (.[] | [(.id[9:11] + ":" + .id[11:13]), .disparador, .ticket, .motivo, .segundos,
          ((.uso.coste // 0) * 10000 | round / 100), (if .codigo == 0 then .rama else "-" end)] | @tsv)' | column -t -s $'\t'
gastado=$(ls "$dia"-*.json 2> /dev/null | grep -v manifiesto | xargs cat 2> /dev/null | jq -s '[.[].uso.coste // 0] | add // 0')
echo; awk -v g="$gastado" -v p="${ROBOT_PRESUPUESTO_DIA:-0.50}" 'BEGIN { printf "hoy: %.2f céntimos de %.0f de presupuesto\n", g * 100, p * 100 }'
