#!/usr/bin/env bash
# Quita los worktrees de las mediciones y sus ficheros de resultados.
for w in /tmp/csn/r/*/; do git -C ~/csn/tienda worktree remove --force "$w"; done
git -C ~/csn/tienda worktree prune
rm -f /tmp/csn/r/*.jsonl /tmp/csn/r/*.juez /tmp/csn/r/filas.txt
