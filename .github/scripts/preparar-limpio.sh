#!/usr/bin/env bash
# Comprueba preparar.sh como lo usa un alumno: en un clon recién hecho, en ~/csn.
# Uso: .github/scripts/preparar-limpio.sh [carpeta del clon]   (por defecto, ~/csn)
set -uo pipefail
CSN=$(cd "${1:-$HOME/csn}" && pwd) || exit 1
cd "$CSN" || exit 1
fallos=0
ok() { echo "ok    $*"; }
roto() {
  fallos=$((fallos + 1))
  local t=${1//%/%25}
  echo "::error title=preparar.sh::${t//$'\n'/%0A}"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then echo "- **preparar.sh**: $1" >> "$GITHUB_STEP_SUMMARY"; fi
}
lista() { tr '\n' ' ' <<< "$1"; }

if salida=$(./preparar.sh 2>&1); then ok "./preparar.sh sale con 0"; else roto "./preparar.sh falla: $salida"; fi
while IFS= read -r l; do echo "      $l"; done <<< "$salida"

for repo in tienda extensiones; do
  [ -d "$repo/.git" ] || { roto "$repo/ no se ha convertido en un repositorio git"; continue; }
  remotas=$(git ls-remote origin "refs/heads/$repo/*" | sed "s#.*refs/heads/$repo/##" | sort)
  locales=$(git -C "$repo" branch --format='%(refname:short)' | sort)
  if [ "$remotas" = "$locales" ]; then ok "$repo/ tiene las ramas del remoto: $(lista "$locales")"
  else roto "$repo/ no tiene las mismas ramas que el remoto. Remoto: $(lista "$remotas"). Local: $(lista "$locales")"; fi
done
for par in tienda:final extensiones:master; do
  repo=${par%:*} rama=${par#*:}
  if [ "$(git -C "$repo" branch --show-current)" = "$rama" ]; then ok "$repo/ queda en $rama"; else roto "$repo/ no queda en la rama $rama"; fi
done

# Toda rama del remoto tiene que tener su resultado esperado en tienda.sh.
conocidas=$(node -e 'for (const r of JSON.parse(process.argv[1])) console.log(r)' "$(bash .github/scripts/tienda.sh --ramas)" | sort)
remotas=$(git ls-remote origin 'refs/heads/tienda/*' | sed 's#.*refs/heads/tienda/##' | sort)
if [ "$conocidas" = "$remotas" ]; then ok "todas las ramas tienen su resultado esperado en .github/scripts/tienda.sh"
else roto "las ramas del remoto ($(lista "$remotas")) no son las de .github/scripts/tienda.sh ($(lista "$conocidas"))"; fi

# verificar.sh (vídeos 24 a 26) compara con las etiquetas rubrica-*: tienen que llegar a la tienda.
faltan=()
for e in rubrica-ticket-003 rubrica-ticket-004-v1 rubrica-ticket-004 rubrica-ticket-005; do
  git -C tienda rev-parse -q --verify "refs/tags/$e" > /dev/null || faltan+=("$e")
done
if [ ${#faltan[@]} = 0 ]; then ok "las etiquetas rubrica-* llegan a tienda/"
else roto "faltan las etiquetas ${faltan[*]} en tienda/: sin ellas ./verificar.sh falla siempre en A5 («no hay ninguna etiqueta rubrica-*»). Hay que publicarlas en el remoto (git push origin ${faltan[*]})."; fi

if [ -z "$(git status --porcelain)" ]; then ok "el repositorio de materiales no ve cambios en tienda/ ni extensiones/"
else roto "tras preparar.sh, git status muestra cambios: $(git status --porcelain | head -n 5 | tr '\n' ' ')"; fi

# Ejecutarlo dos veces no rompe nada.
if salida=$(./preparar.sh 2>&1) && grep -q 'tienda ya es un repositorio' <<< "$salida" && grep -q 'extensiones ya es un repositorio' <<< "$salida"; then
  ok "una segunda ejecución no toca nada"
else roto "la segunda ejecución de preparar.sh no se comporta como se espera: $salida"; fi

# El primer comando del README.
if (cd tienda && npm test > /dev/null 2>&1); then ok "cd tienda && npm test"; else roto "cd tienda && npm test falla en la rama final"; fi

echo
if [ "$fallos" -gt 0 ]; then echo "$fallos comprobaciones rotas."; exit 1; fi
echo "Todo en orden."
