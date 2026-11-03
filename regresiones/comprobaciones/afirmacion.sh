#!/usr/bin/env bash
# Lo que un programa no puede decidir: un juez lee la respuesta y la afirmación del caso. Uso: afirmacion.sh <worktree> <ejecución>
"$(dirname "$0")/../juez.sh" "$2/caso.json" "$2/respuesta.md" > "$2/juez.txt" 2>&1
