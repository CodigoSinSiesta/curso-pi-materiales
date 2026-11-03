#!/usr/bin/env bash
# La prueba oculta, que vive fuera de la tienda y el agente no ha visto. Uso: oculta.sh <worktree> <ejecución>
o=$(jq -r .oculta "$2/caso.json"); TIENDA="$1" node --test "${o/#\~/$HOME}" > "$2/oculta.txt" 2>&1
