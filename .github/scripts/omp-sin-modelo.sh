#!/usr/bin/env bash
# Comprueba, sin modelo ni clave, que los comandos de oh my pi que usa el curso siguen funcionando con la versión instalada.
# Uso: .github/scripts/omp-sin-modelo.sh
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=comun.sh
source "$(dirname "$0")/comun.sh"
X="$RAIZ/extensiones"
ESTADO='{"id":"estado","type":"get_state"}'
# Sin modelo, omp no arranca en modo RPC. Con --model sí, y no le hace falta la clave mientras no haya prompt.
MODELO=(--model deepseek/deepseek-flash)

# Arranque.
if version=$(omp --version 2>&1); then ok "omp --version: $version"; else roto "omp --version" "11" "$version"; fi
if omp --help > "$TMP/ayuda.txt" 2>&1; then ok "omp --help"; else roto "omp --help" "11" "$(error_de "$TMP/ayuda.txt")"; fi

# omp -p --tools … se niega a arrancar si nombras una herramienta que no existe. Se comprueba cada lista
# del curso y que queden activas exactamente esas.
while IFS='|' read -r comando video lista; do
  rpc herramientas "$RAIZ/tienda" "$ESTADO" omp --mode rpc --no-session "${MODELO[@]}" --tools "$lista"
  activas=$(respuesta estado | jq -r '.data.dumpTools // [] | map(.name) | sort | join(",")')
  pedidas=$(tr ',' '\n' <<< "$lista" | sort | paste -sd, -)
  if [ "$rc" != 0 ]; then roto "$comando" "$video" "omp no arranca con --tools $lista: $(error_de "$er")"
  elif [ "$activas" != "$pedidas" ]; then roto "$comando" "$video" "con --tools $lista quedan activas: $activas"
  else ok "$comando (--tools $lista)"; fi
done <<'FIN'
omp --tools read,grep,glob (solo lectura; también sdk-omp/resumen.ts)|11, 21|read,grep,glob
medir/medir.sh y medir/prefijo.sh: omp --tools read,bash,edit,write|22|read,bash,edit,write
FIN

# Lo que PROBLEMAS.md cuenta de find y ls. Si omp vuelve a aceptarlas, hay que actualizarlo; no es un fallo.
rpc find-ls "$RAIZ/tienda" "$ESTADO" omp --mode rpc --no-session "${MODELO[@]}" --tools read,grep,find,ls
if [ "$rc" = 0 ]; then echo "::notice title=omp acepta --tools read,grep,find,ls::Revisa la fila de find y ls en PROBLEMAS.md."
else ok "omp sigue sin aceptar find ni ls en --tools: $(head -n 1 "$er")"; fi

# medir/orquestar.sh (vídeo 25): el modelo del curso, sin-async.yml, la puerta como hook, --max-time y --session-dir.
rpc orquestar "$RAIZ/tienda" "$ESTADO" omp --mode rpc "${MODELO[@]}" --config "$RAIZ/medir/sin-async.yml" \
  --hook "$X/puerta.ts" --max-time 10m --session-dir "$TMP/sesiones"
if [ "$rc" != 0 ]; then
  roto "medir/orquestar.sh (omp -p --mode json --model … --config sin-async.yml --hook puerta.ts --max-time 10m)" "25" \
    "omp no arranca: $(error_de "$er")"
else
  modelo=$(respuesta estado | jq -r '.data.model.provider + "/" + .data.model.id')
  if [ "$modelo" = deepseek/deepseek-flash ]; then ok "medir/orquestar.sh arranca con deepseek/deepseek-flash"
  else roto "--model deepseek/deepseek-flash" "14, 22-26" "omp resuelve el modelo del curso a $modelo"; fi
  if jq -e 'select(.method == "notify" and (.message | startswith("puerta: activa")))' "$ev" > /dev/null \
     && ! grep -q 'Failed to load' "$ev" "$er"; then ok "puerta.ts carga como hook de omp"
  else roto "omp --hook extensiones/puerta.ts" "24, 25" "el hook no carga: $(grep -h 'Failed to load' "$ev" "$er" | head -n 1)"; fi
fi

# medir/medir.sh (vídeo 22): --max-time y el catálogo xd:// apagado.
rpc medir "$RAIZ/tienda" "$ESTADO" omp --mode rpc --no-session --max-time 5m "${MODELO[@]}" --config "$RAIZ/medir/xdev-off.yml"
if [ "$rc" = 0 ]; then ok "medir/medir.sh: omp --max-time 5m --config xdev-off.yml"
else roto "medir/medir.sh (omp -p --mode json --no-session --max-time 5m --config xdev-off.yml)" "22" "omp no arranca: $(error_de "$er")"; fi

# omp-equipo (vídeos 19 a 21): la configuración de equipo y el hook de rutas protegidas.
rpc equipo "$RAIZ/tienda" "$ESTADO" omp --mode rpc --no-session "${MODELO[@]}" \
  --config "$RAIZ/omp-equipo/config.yml" -e "$RAIZ/omp-equipo/rutas-protegidas.ts"
if [ "$rc" = 0 ] && ! grep -q 'Failed to load' "$ev" "$er"; then ok "omp-equipo: config.yml y rutas-protegidas.ts cargan"
else roto "omp --config omp-equipo/config.yml -e omp-equipo/rutas-protegidas.ts" "19, 20, 21" \
  "no carga: $(grep -h 'Failed to load' "$ev" "$er" | head -n 1) $(error_de "$er")"; fi

# Una extensión de Pi dentro de omp (vídeo 20): permisos.ts, y hola.ts como comando.
rpc pi-en-omp "$RAIZ/tienda" "$ESTADO" omp --mode rpc --no-session "${MODELO[@]}" -e "$X/permisos.ts" -e "$X/hola.ts"
if [ "$rc" = 0 ] && ! grep -q 'Failed to load' "$ev" "$er" \
   && jq -e 'select(.method == "setStatus" and .statusKey == "permisos")' "$ev" > /dev/null; then
  ok "permisos.ts (de Pi) carga en omp"
else roto "omp -e extensiones/permisos.ts" "20" "no carga: $(grep -h 'Failed to load' "$ev" "$er" | head -n 1) $(error_de "$er")"; fi
if jq -e 'select(.type == "available_commands_update") | .commands | map(.name) | index("hola")' "$ev" > /dev/null; then
  ok "hola.ts (de Pi) registra /hola en omp"
else roto "omp -e extensiones/hola.ts" "20" "no aparece el comando /hola"; fi

# rpc/aprobador-omp.mjs (vídeo 21): perfil, «ready» y las estadísticas que lee al final.
rpc aprobador "$RAIZ/tienda" '{"id":"2","type":"get_session_stats"}' omp --profile demo --mode rpc --no-session "${MODELO[@]}"
if [ "$rc" = 0 ] && jq -e 'select(.type == "ready")' "$ev" > /dev/null \
   && respuesta 2 | jq -e '.data | (.tokens.total != null) and has("cost") and has("toolCalls")' > /dev/null; then
  ok "rpc/aprobador-omp.mjs: ready y get_session_stats con tokens.total, cost y toolCalls"
else roto "rpc/aprobador-omp.mjs (omp --profile demo --mode rpc)" "21" \
  "falta «ready» o cambian las estadísticas: $(respuesta 2 | cut -c1-200) $(error_de "$er")"; fi

# Los ajustes que usan los YAML del repositorio siguen existiendo (omp ignora en silencio los que no conoce).
for yml in omp-equipo/config.yml medir/sin-async.yml medir/xdev-off.yml; do
  while read -r clave; do
    prueba=$clave
    until [ -z "$prueba" ] || omp config get "$prueba" > /dev/null 2>&1; do
      [[ $prueba == *.* ]] && prueba=${prueba%.*} || prueba=
    done
    if [ -n "$prueba" ]; then ok "$yml: $clave"
    else roto "omp --config $yml" "19-25" "omp ya no conoce el ajuste $clave"; fi
  done < <(node "$SCRIPTS/claves-yaml.mjs" "$RAIZ/$yml")
done

fin
