#!/usr/bin/env bash
# Convierte tienda/ y extensiones/ en repositorios git propios, con las ramas de cada vídeo,
# como estaban en las grabaciones. Ejecútalo una vez, después de clonar en ~/csn.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")" && pwd)"
cd "$RAIZ"
[ "$RAIZ" = "$HOME/csn" ] || echo "Aviso: los scripts del curso esperan esta carpeta en ~/csn (está en $RAIZ)."
git fetch -q origin '+refs/heads/tienda/*:refs/heads/tienda/*' '+refs/heads/extensiones/*:refs/heads/extensiones/*' 2>/dev/null || true
for repo in tienda extensiones; do
  if [ -d "$repo/.git" ]; then echo "$repo ya es un repositorio: no lo toco"; continue; fi
  rama=$([ "$repo" = tienda ] && echo final || echo master)
  rm -rf "$repo"
  git init -q -b "$rama" "$repo"
  git -C "$repo" fetch -q --update-head-ok "$RAIZ" "refs/heads/$repo/*:refs/heads/*"
  git -C "$repo" checkout -q -f "$rama"
  echo "$repo: $(git -C "$repo" branch --format='%(refname:short)' | tr '\n' ' ')"
done
# tienda/ y extensiones/ pasan a ser repositorios propios: que el repositorio de materiales no los vea como cambios.
git update-index --skip-worktree $(git ls-files tienda extensiones) 2>/dev/null || true
echo "Listo. Empieza por: cd ~/csn/tienda && npm test"
