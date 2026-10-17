#!/usr/bin/env bash
# La misma tarea con varios rosters: cada ejecución en su worktree, desde master, y juzgada desde fuera.
# Uso: ./medir.sh <repeticiones>
set -euo pipefail
export PI_CODING_AGENT_DIR=/tmp/csn/pi-agent OMP_PROFILE=demo
TAREA='Añade a src/envio.js una función faltaParaEnvioGratis(subtotal) que devuelva cuántos euros faltan para el envío gratis, redondeados a céntimos, y 0 si ya lo tiene, con la misma validación que gastosEnvio. Añade sus pruebas y ejecuta npm test.'
PI='pi -p --mode json --no-session --no-mcp --no-skills'
OMP='omp -p --mode json --no-session --max-time 5m'
orden() {
  case $1 in
    pi-minimo)       $PI -t read,bash "$TAREA" ;;
    pi-serie)        $PI "$TAREA" ;;
    pi-siete)        $PI -t read,bash,edit,write,grep,find,ls "$TAREA" ;;
    omp-cuatro)      $OMP --tools read,bash,edit,write "$TAREA" ;;
    omp-catalogo)    $OMP "$TAREA" ;;
    omp-sincatalogo) $OMP --config ~/csn/medir/xdev-off.yml "$TAREA" ;;
  esac
}
mkdir -p /tmp/csn/r
for c in pi-minimo pi-serie pi-siete omp-cuatro omp-catalogo omp-sincatalogo; do
  for i in $(seq 1 "$1"); do
    w=/tmp/csn/r/$c-$i
    git -C ~/csn/tienda worktree add -q --detach "$w" master
    cd "$w"
    orden "$c" > "$w.jsonl" 2>/dev/null || true
    npm test > /dev/null 2>&1 && prueba=pasa || prueba=falla
    echo "$prueba $(git status --short | wc -l | tr -d ' ') $(grep -c 'Math.round' src/envio.js || true)" > "$w.juez"
    echo "$c-$i: npm test $prueba"
    cd - > /dev/null
  done
done
