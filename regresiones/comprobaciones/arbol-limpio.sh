#!/usr/bin/env bash
# La revisión no toca ningún fichero. Uso: arbol-limpio.sh <worktree> <ejecución>
[ -z "$(git -C "$1" status --porcelain)" ]
