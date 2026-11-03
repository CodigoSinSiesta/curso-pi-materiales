#!/usr/bin/env bash
# La verificación de la rúbrica, sacada de la etiqueta y no de lo que el agente haya dejado. Uso: verificar.sh <worktree> <ejecución>
t=$(jq -r .ticket "$2/caso.json"); cd "$1" || exit 1
git add -A && git diff --cached --name-only "$(jq -r .partida "$2/caso.json")" > "$2/ficheros.txt"
rm -rf rubricas aceptacion verificar.sh && git checkout -q "rubrica-$t" -- rubricas aceptacion verificar.sh
./verificar.sh "$t" > "$2/verificar.txt" 2>&1
