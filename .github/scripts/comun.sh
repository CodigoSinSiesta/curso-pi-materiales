# shellcheck shell=bash disable=SC2034
# Funciones comunes de pi-sin-modelo.sh y omp-sin-modelo.sh. Se carga con «source».
# Nada de esto necesita modelo ni clave de API: ninguna orden es un prompt.

RAIZ=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SCRIPTS="$RAIZ/.github/scripts"
TMP=$(mktemp -d)
fallos=0

# Un HOME vacío: ni los ajustes ni las credenciales de quien lo ejecute cuentan.
export HOME="$TMP/casa"
mkdir -p "$HOME"
# Ninguna clave: si el agente intentara llamar al modelo, fallaría.
unset ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY DEEPSEEK_API_KEY OPENROUTER_API_KEY

ok() { echo "ok    $*"; }

# roto <comando del curso> <vídeos> <qué pasa>
roto() {
  fallos=$((fallos + 1))
  echo "::error title=$(escapa_titulo "Se ha roto: $1")::$(escapa "Vídeo $2. $3")"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then echo "- **Se ha roto: \`$1\`** (vídeo $2). $3" >> "$GITHUB_STEP_SUMMARY"; fi
}

# Escapes de los comandos de flujo de GitHub Actions (el título tampoco admite «:» ni «,»).
escapa() { local t=${1//%/%25}; t=${t//$'\r'/%0D}; printf '%s' "${t//$'\n'/%0A}"; }
escapa_titulo() { local t; t=$(escapa "$1"); t=${t//:/%3A}; printf '%s' "${t//,/%2C}"; }

# rpc <nombre> <carpeta> <órdenes JSON, una por línea> <comando…>
# Deja los eventos en $TMP/<nombre>.jsonl, la salida de error en $TMP/<nombre>.jsonl.err y el código en $rc.
rpc() {
  local nombre=$1 carpeta=$2 ordenes=$3
  shift 3
  (cd "$carpeta" && node "$SCRIPTS/rpc.mjs" "$TMP/$nombre.jsonl" "$ordenes" "$@")
  rc=$?
  ev="$TMP/$nombre.jsonl"
  er="$TMP/$nombre.jsonl.err"
}

# Primeras líneas de la salida de error, para el mensaje.
error_de() { tr '\n' ' ' < "$1" | cut -c1-300; }

# Respuesta a una orden (por id) en los eventos de $ev.
respuesta() { jq -c --arg id "$1" 'select(.type == "response" and .id == $id)' "$ev"; }

fin() {
  echo
  if [ "$fallos" -gt 0 ]; then
    echo "$fallos comprobaciones rotas. Cada «Se ha roto» dice qué comando del curso deja de funcionar."
    exit 1
  fi
  echo "Todo en orden."
}
