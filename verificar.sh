#!/usr/bin/env bash
# Criterios automáticos de las rúbricas. Uso: ./verificar.sh [id…]  (sin id: las que ya están en pasa)
# Solo sale con 0 o 1 (lo usa también /loop --until). Todo va a stdout, en orden.
set -u
exec 2>&1
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
ids="${*:-$(node -e 'const f=JSON.parse(require("fs").readFileSync("funcionalidades.json","utf8"));
  console.log(f.funcionalidades.filter(x=>x.estado==="pasa").map(x=>x.id).join(" "))')}"
fallo=0
for f in src/*.js; do node --check "$f" || fallo=1; done                 # A1 estática
npm test --silent || fallo=1                                              # A2 ejecución
for id in $ids; do                                                        # A3 sistema
  node -e 'const f=JSON.parse(require("fs").readFileSync("funcionalidades.json","utf8"));
    process.exit(f.funcionalidades.some(x=>x.id===process.argv[1])?0:1)' "$id" || {
    echo "ERROR: $id no está en funcionalidades.json."; echo "POR QUÉ: un id mal escrito no puede dar verde."
    echo "CÓMO: usa uno de los ids de funcionalidades.json."; fallo=1; continue; }
  [ -f "aceptacion/$id.mjs" ] && { node --test --test-reporter=spec "aceptacion/$id.mjs" || fallo=1; }
done
node -e 'const f=JSON.parse(require("fs").readFileSync("funcionalidades.json","utf8"));
  const m=f.funcionalidades.filter(x=>x.estado==="pasa"&&!(x.evidencias||[]).length).map(x=>x.id);
  if(m.length){console.log("ERROR: "+m.join(", ")+" en pasa sin evidencias.\nPOR QUÉ: pasa exige la verificación ejecutada y anotada.\nCÓMO: ejecuta ./verificar.sh y anota su salida.");process.exit(1)}' || fallo=1   # A4
base=$(git describe --tags --abbrev=0 --match 'rubrica-*' 2>/dev/null) || base=""   # A5: última rúbrica
if [ -z "$base" ]; then
  echo "ERROR: no hay ninguna etiqueta rubrica-* en la historia."; echo "POR QUÉ: A5 compara con la última rúbrica."
  echo "CÓMO: etiqueta el commit de la rúbrica (git tag rubrica-<id>)."; fallo=1
else git diff --quiet "$base" -- rubricas aceptacion verificar.sh || {
  echo "ERROR: la verificación ha cambiado desde $base."
  echo "POR QUÉ: quien hace el trabajo no cambia la verificación."
  echo "CÓMO: git checkout $base -- rubricas aceptacion verificar.sh"; fallo=1; }
fi
exit $fallo
