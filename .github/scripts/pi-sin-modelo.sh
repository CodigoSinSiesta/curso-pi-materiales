#!/usr/bin/env bash
# Comprueba, sin modelo ni clave, que los comandos de Pi que usa el curso siguen funcionando con la versión instalada.
# Uso: .github/scripts/pi-sin-modelo.sh   (PI_PAQUETE: carpeta del paquete npm, si no está en `npm root -g`)
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=comun.sh
source "$(dirname "$0")/comun.sh"
# El paquete del mismo pi que se ejecuta (con varios Node, `npm root -g` puede apuntar a otro).
if [ -z "${PI_PAQUETE:-}" ]; then
  PI_PAQUETE=$(dirname "$(readlink -f "$(command -v pi)")")
  until [ "$PI_PAQUETE" = / ] || grep -qs '"name": "@earendil-works/pi-coding-agent"' "$PI_PAQUETE/package.json"; do
    PI_PAQUETE=$(dirname "$PI_PAQUETE")
  done
fi
X="$RAIZ/extensiones"
ESTADO='{"id":"estado","type":"get_state"}'
COMANDOS='{"id":"comandos","type":"get_commands"}'

# Arranque.
if version=$(pi --version 2>&1); then ok "pi --version: $version"; else roto "pi --version" "02" "$version"; fi
if pi --help > "$TMP/ayuda.txt" 2>&1; then ok "pi --help"; else roto "pi --help" "02" "$(error_de "$TMP/ayuda.txt")"; fi
[ -f "$PI_PAQUETE/package.json" ] || roto "npm install -g @earendil-works/pi-coding-agent" "02, 10" "no encuentro el paquete en $PI_PAQUETE"

# Herramientas, extensiones y SDK, como librería (Pi ignora en silencio un --tools con nombres que no existen).
node "$SCRIPTS/pi-sdk.mjs" "$PI_PAQUETE" "$RAIZ" > "$TMP/sdk.txt" 2>&1 || roto "sdk/resumen.ts" "10" "pi-sdk.mjs ha fallado: $(error_de "$TMP/sdk.txt")"
grep '^ok' "$TMP/sdk.txt"
while IFS=$'\t' read -r _ comando video detalle; do roto "$comando" "$video" "$detalle"; done < <(grep $'^ROTO\t' "$TMP/sdk.txt")

# scripts/revisar.sh y rpc/aprobador.mjs (vídeo 10): las opciones, el modelo del curso y permisos.ts.
rpc revisar "$RAIZ/tienda" "$ESTADO" pi --mode rpc --no-session --no-skills --no-approve \
  --model deepseek/deepseek-flash -e "$X/permisos.ts" --tools read,grep,find,ls
if [ "$rc" != 0 ]; then
  roto "scripts/revisar.sh (pi --mode json --no-session --no-skills --no-approve -e permisos.ts --tools …)" "10" "Pi no arranca: $(error_de "$er")"
else
  modelo=$(respuesta estado | jq -r '.data.model.provider + "/" + .data.model.id')
  if [ "$modelo" != deepseek/deepseek-flash ] || grep -q 'not found' "$er"; then
    roto "--model deepseek/deepseek-flash" "04, 10, 22-26" "Pi ya no conoce el modelo del curso ($modelo): $(error_de "$er")"
  else ok "scripts/revisar.sh arranca con deepseek/deepseek-flash"; fi
  if jq -e 'select(.method == "setStatus" and .statusKey == "permisos")' "$ev" > /dev/null; then ok "permisos.ts carga y pinta su estado"
  else roto "pi -e extensiones/permisos.ts" "08, 10" "la extensión no ha pintado su estado (setStatus permisos)"; fi
fi

# medir.sh y prefijo.sh (vídeo 22): todas las combinaciones de opciones que usan.
while IFS='|' read -r comando opciones; do
  read -r -a opts <<< "$opciones"
  rpc medir "$RAIZ/tienda" "$ESTADO" pi --mode rpc --no-session --no-mcp --no-skills "${opts[@]}"
  if [ "$rc" = 0 ]; then ok "$comando"; else roto "$comando" "22" "Pi no arranca: $(error_de "$er")"; fi
done <<'FIN'
medir/prefijo.sh: pi --no-tools|--no-tools
medir/medir.sh: pi -t read,bash|-t read,bash
medir/medir.sh: pi -t read,bash,edit,write,grep,find,ls|-t read,bash,edit,write,grep,find,ls
medir/prefijo.sh: pi -t +codemode|-t +codemode
FIN

# Las extensiones del curso (vídeos 08, 09 y 24), una a una y como paquete.
rpc extensiones "$RAIZ/tienda" "$COMANDOS" pi --mode rpc --no-session \
  -e "$X/hola.ts" -e "$X/tests.ts" -e "$X/permisos.ts" -e "$X/puerta.ts"
if [ "$rc" != 0 ]; then
  roto "pi -e extensiones/<extensión>.ts" "08, 09, 24" "alguna extensión no carga: $(error_de "$er")"
else
  if respuesta comandos | jq -e '.data.commands | map(.name) | index("hola")' > /dev/null; then ok "hola.ts registra /hola"
  else roto "pi -e extensiones/hola.ts" "08" "no aparece el comando /hola"; fi
  if jq -e 'select(.method == "setStatus" and .statusKey == "tests")' "$ev" > /dev/null; then ok "tests.ts carga"
  else roto "pi -e extensiones/tests.ts" "08" "la extensión no ha pintado su estado (setStatus tests)"; fi
  if jq -e 'select(.method == "notify" and (.message | startswith("puerta: activa")))' "$ev" > /dev/null; then ok "puerta.ts carga"
  else roto "pi -e extensiones/puerta.ts" "24" "no avisa de que está activa"; fi
fi
rpc paquete "$RAIZ/tienda" "$COMANDOS" pi --mode rpc --no-session -e "$X"
if [ "$rc" = 0 ] && respuesta comandos | jq -e '.data.commands | map(.name) | index("hola")' > /dev/null; then
  ok "extensiones/ carga como paquete de Pi"
else roto "pi install ./extensiones (paquete de Pi)" "09" "el paquete no carga o no trae /hola: $(error_de "$er")"; fi

# Confianza de proyecto (vídeo 05): la extensión de repo-ajeno solo carga si confías en el proyecto.
rpc ajeno "$RAIZ/repo-ajeno" "$ESTADO" pi --mode rpc --no-session
if [ "$rc" = 0 ] && ! grep -q 'Extensión del repositorio cargada' "$ev"; then ok "repo-ajeno: sin confiar, su extensión no carga"
else roto "pi en repo-ajeno/ (sin confiar)" "05" "la extensión del repositorio carga sin confiar en él, o Pi no arranca: $(error_de "$er")"; fi
rpc ajeno-a "$RAIZ/repo-ajeno" "$ESTADO" pi --mode rpc --no-session -a
if [ "$rc" = 0 ] && grep -q 'Extensión del repositorio cargada' "$ev"; then ok "repo-ajeno: con -a, su extensión carga"
else roto "pi -a en repo-ajeno/" "05" "con -a la extensión del repositorio no carga: $(error_de "$er")"; fi

fin
