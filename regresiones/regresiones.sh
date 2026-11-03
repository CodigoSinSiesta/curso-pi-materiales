#!/usr/bin/env bash
# La batería: cada caso de casos/, n veces, en la tanda «bateria». Sale con 0 o con 1 según UMBRAL (por defecto 1:
# todas las ejecuciones de cada caso tienen que pasar). Uso: ./regresiones.sh <repeticiones>
set -euo pipefail
cd "$(dirname "$0")"
for c in casos/*.json; do TANDA=bateria ./reproducir.sh "$c" "$1"; done
./resumen-regresiones.sh bateria
