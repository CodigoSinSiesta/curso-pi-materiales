#!/usr/bin/env bash
# Revisión de una rama con Pi. Uso: scripts/revisar.sh [rama-base]
set -uo pipefail
base="${1:-master}"
permisos="${PERMISOS:-$HOME/csn/extensiones/permisos.ts}"
salida="${SALIDA:-/tmp/csn/revision}"
mkdir -p "$salida"

# 1. Lo que se puede comprobar sin modelo, lo comprueba el script
#    (en CI llega ya hecho, desde un paso sin la clave: TESTS=código).
if [ -n "${TESTS:-}" ]; then tests=$TESTS
else npm test > "$salida/tests.txt" 2>&1; tests=$?; fi

# 2. Pi revisa el diff: sin sesión, con la red de seguridad
#    y, si PI_TOOLS está definida, solo con esas herramientas.
git diff "$base" | pi --mode json --no-session --no-skills --no-approve \
  --model deepseek/deepseek-flash -e "$permisos" ${PI_TOOLS:+--tools "$PI_TOOLS"} \
  "Revisa este diff. npm test ha salido con código $tests.
   Puedes leer ficheros. No modifiques nada.
   Responde en Markdown: resumen, riesgos y una última línea VEREDICTO: OK o VEREDICTO: CAMBIOS." \
  > "$salida/eventos.jsonl" 2> "$salida/pi.err"

# 3. Leer el resultado de los eventos, no del código de salida de Pi.
cd "$salida"
final=$(jq -r 'select(.type=="message_end" and .message.role=="assistant") | .message.stopReason' eventos.jsonl | tail -n 1)
jq -r 'select(.type=="message_end" and .message.role=="assistant") | .message.content[] | select(.type=="text") | .text' \
  eventos.jsonl | tail -n 40 > informe.md
jq -c 'select(.type=="tool_execution_end" and .isError) | {toolName, motivo: (.result.content[0].text | gsub("\\s+"; " ") | .[0:70])}' \
  eventos.jsonl > errores.jsonl

[ "$final" = "stop" ] || { echo "Pi no terminó bien: $final" >&2; exit 3; }
[ -s errores.jsonl ] && echo "Aviso: herramientas con error o bloqueadas (errores.jsonl)" >&2
exit "$tests"
