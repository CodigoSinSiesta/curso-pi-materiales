#!/usr/bin/env bash
# Juez: Pi sin herramientas y con un modelo barato. Recibe la afirmación del caso y un texto, y decide si el texto la
# cumple. Sale con 0 si PASA y con 1 si FALLA. Uso: ./juez.sh <caso.json> <texto>
set -uo pipefail
export PI_CODING_AGENT_DIR=${PI_CODING_AGENT_DIR:-/tmp/csn/pi-agent}
afirmacion=$(jq -r .afirmacion "$1")
{ echo "<texto>"; cat "$2"; echo "</texto>"; } |
  pi -p --no-tools --no-session --no-context-files --no-skills --no-extensions --model deepseek/deepseek-flash \
  "Eres un juez. Lee el texto que va entre <texto> y </texto> y decide si cumple esta afirmación: $afirmacion
   Que el texto cite el código no basta: tiene que decir que eso es un problema o un riesgo.
   Responde con una frase que cite la parte del texto que decide, y en la última línea, solo VEREDICTO: PASA o VEREDICTO: FALLA." \
  | tee /dev/stderr | tail -1 | grep -q 'VEREDICTO: PASA'
