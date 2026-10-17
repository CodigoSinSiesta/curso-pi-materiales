#!/usr/bin/env bash
# Arranque estándar: dónde estás, qué hay sin commitear, si las pruebas pasan y qué toca ahora.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "==> Carpeta: ${PWD/#"$HOME"/\~}"
echo "==> Node: $(node --version)"
echo "==> Cambios sin commitear:"
git status --short
echo "==> Verificación de base (npm test)"
npm test --silent > /dev/null 2>&1 && echo "    pasa" || { echo "    FALLA: arregla esto antes de seguir"; exit 1; }
echo "==> Funcionalidad activa o siguiente:"
node -e '
const { funcionalidades: f } = JSON.parse(require("fs").readFileSync("funcionalidades.json", "utf8"));
const activa = f.find(x => x.estado === "en_curso")
  ?? f.filter(x => x.estado === "sin_empezar").sort((a, b) => a.prioridad - b.prioridad)[0];
console.log(activa ? `    ${activa.id} · ${activa.titulo} · ${activa.estado}` : "    ninguna pendiente");'
