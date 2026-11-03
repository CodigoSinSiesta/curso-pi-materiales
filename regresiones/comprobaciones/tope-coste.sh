#!/usr/bin/env bash
# El coste de la ejecución no pasa del tope del caso. Uso: tope-coste.sh <worktree> <ejecución>
tope=$(jq -r .tope.dolares "$2/caso.json")
coste=$(jq -s '[.[] | select(.type=="message_end" and .message.role=="assistant") | .message.usage.cost.total] | add // 0' "$2/eventos.jsonl")
awk -v c="$coste" -v t="$tope" 'BEGIN { exit !(c <= t) }'
