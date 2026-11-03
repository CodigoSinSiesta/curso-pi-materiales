#!/usr/bin/env bash
# El agente termina sin error: omp sale con 0 y su última respuesta acaba en «stop». Uso: sin-error.sh <worktree> <ejecución>
[ "$(cat "$2/salida")" = 0 ] || exit 1
ultima=$(jq -r 'select(.type=="message_end" and .message.role=="assistant") | .message.stopReason' "$2/eventos.jsonl" | tail -1)
[ "$ultima" = stop ]
