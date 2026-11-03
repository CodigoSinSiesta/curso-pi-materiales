#!/usr/bin/env bash
# Comprueba una rama de la tienda contra lo que se espera de ella en los vídeos.
# Algunas ramas fallan a propósito: aquí se declara cada resultado esperado.
#
# Uso: tienda.sh --ramas                         las ramas que conoce, en JSON (para la matriz del CI)
#      tienda.sh <rama> <carpeta-tienda> <carpeta-fuera>
set -uo pipefail

RAMAS=(master iva-antes iva-despues umbral-50 andamiaje verificar hecho-falso puerta-prueba orquestar cuadre ticket-005 bucle-25 final)

# Etiquetas de las rúbricas: verificar.sh compara con ellas (criterio A5).
ETIQUETAS=(
  "rubrica-ticket-003 3a36c10"
  "rubrica-ticket-004-v1 d265135"
  "rubrica-ticket-004 0ad4487"
  "rubrica-ticket-005 6ff1952"
)

# Qué se espera de cada rama. npm: código de npm test. verificar: código de ./verificar.sh sin argumentos
# (- si la rama no lo tiene). extra: comprobaciones de la demo, «qué código esperado».
esperado() {
  extra=()
  case $1 in
    master|iva-antes|iva-despues|andamiaje) npm=0 verificar=- ;;
    # Vídeo 10: sube el envío gratis a 50 € sin tocar las pruebas. Fallan 3 de 15: es lo que revisa Pi.
    umbral-50) npm=1 verificar=- ;;
    verificar|puerta-prueba|orquestar) npm=0 verificar=0 ;;
    # Vídeo 24: un «hecho» falso. npm test pasa, pero la aceptación ve 45,74 € donde la tienda da 50,69 €.
    hecho-falso) npm=0 verificar=1 ;;
    # Vídeo 25: el desglose «cuadra» con la aceptación v1, pero la prueba oculta lo pilla (Goodhart).
    cuadre) npm=0 verificar=0 extra=("verificar ticket-004 0" "oculta 004 1") ;;
    bucle-25) npm=0 verificar=0 extra=("oculta 004 0") ;;
    # Vídeo 26: ticket-005 es el proyecto final; en final está por hacer, en ticket-005 está hecho.
    final) npm=0 verificar=0 extra=("oculta 004 0" "verificar ticket-005 1" "oculta 005 1") ;;
    ticket-005) npm=0 verificar=0 extra=("verificar ticket-005 0" "oculta 005 0") ;;
    *) return 1 ;;
  esac
}

if [ "${1:-}" = --ramas ]; then
  printf '%s\n' "${RAMAS[@]}" | node -e 'console.log(JSON.stringify(require("fs").readFileSync(0,"utf8").trim().split("\n")))'
  exit 0
fi

rama=${1:?Uso: tienda.sh <rama> <carpeta-tienda> <carpeta-fuera>}
tienda=$(cd "${2:?falta la carpeta de la tienda}" && pwd) || exit 1
fuera=$(cd "${3:?falta la carpeta fuera/}" && pwd) || exit 1
fallos=0
tmp=$(mktemp -d)

roto() { local t=${1//%/%25}; echo "::error title=tienda/$rama::${t//$'\n'/%0A}"; fallos=1; }
compara() { # qué, esperado, obtenido
  if [ "$2" = "$3" ]; then echo "ok    $1 sale con $3, como se espera"
  else roto "$1 sale con $3 y se esperaba $2"; fi
}

esperado "$rama" || { roto "rama sin resultado esperado: añádela a .github/scripts/tienda.sh"; exit 1; }
cd "$tienda" || exit 1

# Sin las etiquetas, A5 falla en todas las ramas. El job «preparar» comprueba que lleguen al alumno;
# aquí se crean si faltan, para probar el contenido de cada rama por separado.
if [ -z "$(git tag -l 'rubrica-*')" ]; then
  echo "::warning title=Faltan las etiquetas rubrica-*::El repositorio no trae las etiquetas rubrica-*. Se crean aquí para probar la rama."
  for e in "${ETIQUETAS[@]}"; do
    read -r -a trozos <<< "$e"; set -- "${trozos[@]}"
    git cat-file -e "$2^{commit}" 2>/dev/null && git tag "$1" "$2"
  done
fi

if [ -f package-lock.json ]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund --no-package-lock; fi

npm test > "$tmp/npm-test.txt" 2>&1; codigo=$?
compara "npm test" "$npm" "$codigo"
grep -E '^ℹ (tests|pass|fail) ' "$tmp/npm-test.txt" | tr '\n' ' '; echo

if [ "$verificar" = - ]; then
  [ -e verificar.sh ] && roto "la rama tiene verificar.sh y no se esperaba"
else
  ./verificar.sh > "$tmp/verificar.txt" 2>&1; codigo=$?
  compara "./verificar.sh" "$verificar" "$codigo"
  [ "$codigo" = "$verificar" ] || grep -E 'ERROR|CÓMO|not ok' "$tmp/verificar.txt" | head -n 6
  if [ "$rama" = hecho-falso ] && ! grep -q '45,74 €' "$tmp/verificar.txt"; then
    roto "./verificar.sh falla, pero no por el total del ticket (45,74 € frente a 50,69 €)"
  fi
fi

for e in "${extra[@]}"; do
  read -r -a trozos <<< "$e"; set -- "${trozos[@]}"
  case $1 in
    verificar) ./verificar.sh "$2" > /dev/null 2>&1; compara "./verificar.sh $2" "$3" $? ;;
    oculta) TIENDA="$tienda" node --test "$fuera/ticket-$2-oculta.mjs" > /dev/null 2>&1
            compara "la prueba oculta fuera/ticket-$2-oculta.mjs" "$3" $? ;;
  esac
done

exit $fallos
