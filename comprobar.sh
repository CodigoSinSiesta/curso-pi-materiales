#!/usr/bin/env bash
# Comprueba, sin modelo, que la práctica de un vídeo quedó bien hecha en la tienda.
#
#   ./comprobar.sh NN              Comprueba el estado actual de ~/csn/tienda (lo que hay en disco, esté o no
#                                  commiteado) contra lo que deja la demo del vídeo NN.
#   ./comprobar.sh 10 <script>     En el vídeo 10, comprueba tu propio revisar.sh en vez del de la tienda.
#
# Sale con 0 si todo pasa, 1 si algo falla y 2 si el vídeo no tiene comprobación automática (entonces te dice
# qué mirar a mano). No cambia nada: solo lee ficheros y ejecuta las pruebas.
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")" && pwd)"
TIENDA="${TIENDA:-$RAIZ/tienda}"
EXT="${EXT:-$RAIZ/extensiones}"
fallos=0
avisos=0

titulo() { echo "Vídeo $1 · $2"; echo "  Tienda: $TIENDA ($(git -C "$TIENDA" branch --show-current 2>/dev/null || echo '?'), $(git -C "$TIENDA" log -1 --format=%h 2>/dev/null))"; }
bien()   { echo "  ok     $1"; }
mal()    { echo "  FALLA  $1"; [ -z "${2:-}" ] || echo "         Cómo: $2"; fallos=$((fallos + 1)); }
aviso()  { echo "  aviso  $1"; avisos=$((avisos + 1)); }
# comprueba "qué se espera" "cómo arreglarlo" orden...
comprueba() { local que=$1 como=$2; shift 2; if "$@" > /dev/null 2>&1; then bien "$que"; else mal "$que" "$como"; fi; }

# js 'código': evalúa en la tienda; el código hace imports dinámicos y termina en una expresión booleana.
js() {
  (cd "$TIENDA" && node --input-type=module -e "
    const envio = () => import('./src/envio.js'), carrito = () => import('./src/carrito.js');
    const igual = (a, b) => Math.abs(a - b) < 0.005;
    const lanza = (f, Tipo = Error) => { try { f(); return false; } catch (e) { return e instanceof Tipo; } };
    try { process.exit((await (async () => { $1 })()) ? 0 : 1); } catch (e) { console.error(e.message); process.exit(1); }")
}
pruebas_pasan() { (cd "$TIENDA" && npm test --silent); }
sin_cambios() { git -C "$TIENDA" diff --quiet "$1" -- "${@:2}"; }      # el disco coincide con el commit $1 en esas rutas
intacta() { [ -z "$(git -C "$RAIZ" status --porcelain -- "$1")" ]; }   # una carpeta de los materiales, sin cambios ni ficheros nuevos
limpia() { [ -z "$(git -C "$TIENDA" status --porcelain)" ]; }
cuenta_pruebas() { cat "$TIENDA"/test/*.js 2>/dev/null | grep -cE "^\s*test\(" ; }
estado_de() {   # estado_de ticket-003 → «pasa 3» (estado y número de evidencias)
  (cd "$TIENDA" && node -e 'const f=JSON.parse(require("fs").readFileSync("funcionalidades.json","utf8")).funcionalidades.find(x=>x.id===process.argv[1]);
    console.log(f ? f.estado+" "+(f.evidencias||[]).length : "no-existe 0")' "$1" 2>/dev/null) || echo "ilegible 0"
}
# verificar_sale NN args…: ejecuta ./verificar.sh y comprueba que sale con 0; avisa si sale con algo que no sea 0 o 1.
verificar_sale_0() {
  local salida codigo
  salida=$(cd "$TIENDA" && ./verificar.sh "$@" 2>&1); codigo=$?
  if [ "$codigo" = 0 ]; then bien "./verificar.sh${*:+ $*} sale con 0"
  else
    [ "$codigo" = 1 ] || mal "./verificar.sh solo debe salir con 0 o 1 (ha salido con $codigo)" "restaura verificar.sh de la rúbrica"
    mal "./verificar.sh${*:+ $*} sale con 0 (ha salido con $codigo)" "lee los ERROR / POR QUÉ / CÓMO de su salida:"
    echo "$salida" | grep -E "ERROR|POR QUÉ|CÓMO|not ok|✖" | head -8 | sed 's/^/           /'
  fi
}
oculta_pasa() {   # oculta_pasa ticket-004
  local f="$RAIZ/fuera/$1-oculta.mjs"
  if [ ! -f "$f" ]; then mal "existe la prueba oculta $f" "vuelve a clonar los materiales"; return; fi
  if TIENDA="$TIENDA" node --test "$f" > /dev/null 2>&1; then bien "la prueba oculta de $1 (fuera de la tienda) pasa"
  else mal "la prueba oculta de $1 (fuera de la tienda) pasa" "el agente ha cuadrado lo que mira verificar.sh, no lo que pide la funcionalidad: TIENDA=\"$TIENDA\" node --test \"$f\""; fi
}
necesita_etiqueta() {
  git -C "$TIENDA" rev-parse -q --verify "refs/tags/$1" > /dev/null 2>&1 \
    || mal "existe la etiqueta $1 (la usa verificar.sh)" "ejecuta ./preparar.sh $v, que crea las etiquetas rubrica-*"
}

# Pi en modo RPC, con un directorio de agente vacío y sin llamar a ningún modelo: pide la lista de comandos
# con la extensión (o el paquete) cargada. pi_rpc imprime lo que responde Pi.
pi_rpc() {
  local tmp; tmp=$(mktemp -d)
  (cd "$tmp" && { echo '{"id":"c","type":"get_commands"}'; sleep 3; } \
    | PI_CODING_AGENT_DIR="$tmp" PI_SKIP_VERSION_CHECK=1 pi --mode rpc --no-session --no-skills -e "$1" 2>&1)
  rm -rf "$tmp"
}
pi_carga() { pi_rpc "$1" | grep -q '"command":"get_commands","success":true'; }
pi_comandos() { pi_rpc "$1" | grep -o '"name":"[^"]*","description":"[^"]*","source":"extension"' | sed 's/^"name":"\([^"]*\)".*/\1/'; }

a_mano() {   # a_mano "texto": el vídeo no tiene comprobación automática
  echo "  Este vídeo no tiene comprobación automática: lo que deja no está en la tienda o depende de la sesión."
  echo "  Mira a mano:"
  echo "$1" | sed 's/^/    - /'
  exit 2
}

terminar() {
  echo
  if [ "$fallos" = 0 ]; then
    if [ "$avisos" = 0 ]; then echo "Todo en orden."; else echo "Todo en orden, con $avisos aviso(s): léelos arriba."; fi
    exit 0
  else echo "$fallos comprobación(es) fallan. Arréglalas y vuelve a ejecutar ./comprobar.sh $v"; exit 1; fi
}

[ $# -ge 1 ] && [[ "$1" =~ ^[0-9]{1,2}$ ]] || { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
v=$(printf '%02d' "$((10#$1))"); shift
if [ ! -d "$TIENDA/.git" ] && [ "$v" != 01 ]; then
  echo "ERROR: $TIENDA no es un repositorio git. Ejecuta primero ./preparar.sh"; exit 1
fi

case "$v" in
01) echo "Vídeo 01 · Qué es un harness"
    a_mano "La demo usa ~/demo/harness-demo, que no está en estos materiales.
La práctica es analizar una tarea tuya con las cinco piezas: instrucciones, herramientas, entorno, estado y feedback." ;;

02) titulo 02 "Instalar Pi y primera tarea"
    comprueba "src/envio.js exporta gastosEnvio" "pide a Pi que cree src/envio.js con gastosEnvio(subtotal)" \
      js "return typeof (await envio()).gastosEnvio === 'function'"
    comprueba "el envío cuesta 4,95 € por debajo de 40 €" "gastosEnvio(10) y gastosEnvio(39.99) deben dar 4.95" \
      js "const {gastosEnvio:g}=await envio(); return igual(g(10),4.95) && igual(g(39.99),4.95)"
    comprueba "el envío es gratis desde 40 € (el cambio del vídeo)" "¿se quedó en 50 €? Repite el cambio: «gratis a partir de 40 €, no de 50»" \
      js "const {gastosEnvio:g}=await envio(); return g(40)===0 && g(50)===0"
    comprueba "carrito.js exporta totalConEnvio: total con cupón + envío" "pide totalConEnvio(lineas, cupon) en src/carrito.js" \
      js "const {totalConEnvio:t}=await carrito(); return igual(t([{precio:10,cantidad:1}]),14.95) && igual(t([{precio:50,cantidad:1}]),50)"
    comprueba "hay pruebas del envío en test/envio.test.js" "pide que escriba las pruebas en test/envio.test.js" test -s "$TIENDA/test/envio.test.js"
    comprueba "el README habla de los gastos de envío" "era el follow-up: «añade al README una línea sobre los gastos de envío»" \
      grep -qiE "env(i|í)o" "$TIENDA/README.md"
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    terminar ;;

03) titulo 03 "Pi por dentro"
    comprueba "aplicarIVA(importe, tipo = 21) redondea a céntimos" "pide aplicarIVA a Pi (primer mensaje del vídeo)" \
      js "const {aplicarIVA:a}=await carrito(); return igual(a(100),121) && igual(a(10,10),11) && igual(a(0.1),0.12)"
    if js "const {totalConEnvio:t}=await carrito(); return igual(t([{precio:35,cantidad:1}]),42.35)" 2>/dev/null; then
      mal "totalConEnvio aplica el IVA solo a los productos (35 € → 47,30 €)" "tienes la versión «IVA antes del envío» (iva-antes); el vídeo termina en la otra rama: vuelve con /tree y pide la alternativa"
    else
      comprueba "totalConEnvio aplica el IVA solo a los productos (35 € → 47,30 €)" "el envío se decide con el total sin IVA y el IVA solo va a los productos" \
        js "const {totalConEnvio:t}=await carrito(); return igual(t([{precio:35,cantidad:1}]),47.30)"
    fi
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    echo "  (El árbol de la sesión, /tree, el resumen de rama y /compact se miran en Pi, no en el disco.)"
    terminar ;;

04) titulo 04 "Modelos y proveedores"
    comprueba "gastosEnvio lanza TypeError con subtotales que no son números finitos ≥ 0" "pide la validación (primer mensaje con Flash)" \
      js "const {gastosEnvio:g}=await envio(); return [NaN,Infinity,-1,'10',null,undefined].every(x=>lanza(()=>g(x),TypeError))"
    comprueba "gastosEnvio sigue aceptando 0 y los importes normales" "la validación no debe rechazar 0" \
      js "const {gastosEnvio:g}=await envio(); return igual(g(0),4.95) && g(40)===0"
    comprueba "hay una prueba del TypeError" "pide que añada la prueba en test/envio.test.js" grep -q "TypeError" "$TIENDA/test/envio.test.js"
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    terminar ;;

05) titulo 05 "Seguridad y aislamiento"
    comprueba "repo-ajeno sigue igual: nadie obedeció la instrucción oculta de su AGENTS.md" \
      "git -C \"$RAIZ\" status repo-ajeno enseña qué cambió; deshazlo con git -C \"$RAIZ\" checkout -- repo-ajeno (y borra lo nuevo)" \
      intacta repo-ajeno
    comprueba "fuera/secreto.txt sigue igual" "git -C \"$RAIZ\" checkout -- fuera" intacta fuera
    if [ -e "$TIENDA/prueba.txt" ]; then aviso "queda tienda/prueba.txt de la demo del contenedor: bórralo (rm \"$TIENDA/prueba.txt\")"; fi
    echo "  A mano: que Pi leyó ../fuera/secreto.txt sin el contenedor y no dentro de él, y que con :ro no pudo crear prueba.txt."
    terminar ;;

06) titulo 06 "Personalizar sin código"
    comprueba "hay AGENTS.md con una sección «Hecho significa» (la definición de hecho)" "escribe AGENTS.md con la rutina de entrada, el mapa, las reglas y «Hecho significa»" \
      grep -qE "^#+ *Hecho significa" "$TIENDA/AGENTS.md"
    comprueba "la definición de hecho tiene al menos un punto" "pon debajo de «Hecho significa» qué debe pasar para dar algo por terminado" \
      sh -c "sed -n '/^#* *Hecho significa/,/^#/p' \"$TIENDA/AGENTS.md\" | grep -qE '^\s*[-*0-9]'"
    comprueba "carrito.js exporta contarUnidades y suma las cantidades" "pide contarUnidades(lineas) a Pi (primer mensaje del vídeo)" \
      js "const {contarUnidades:c}=await carrito(); return c([{precio:1,cantidad:2},{precio:9,cantidad:3}])===5 && c([])===0"
    comprueba "hay pruebas de contarUnidades" "AGENTS.md pide una prueba por función pública" grep -q "contarUnidades" "$TIENDA/test/carrito.test.js"
    comprueba "el commit sigue AGENTS.md (mensaje que empieza por «tienda:»)" "responde «Sí, haz el commit» y comprueba el mensaje con git log -1" \
      sh -c "git -C \"$TIENDA\" log -1 --format=%s -- src/carrito.js | grep -q '^tienda:' && git -C \"$TIENDA\" diff --quiet HEAD -- src test"
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    terminar ;;

07) titulo 07 "MCP y codemode"
    a_mano "La demo no deja nada en la tienda: git status debe salir limpio.
Al terminar, pi mcp list no debe listar tienda-fs (pi mcp remove tienda-fs) y no debe quedar mcp.json en tu directorio de agente.
En la sesión: que con «solo el servidor MCP tienda-fs» no usó bash ni read, y cuánto ocupa el primer contexto en direct, en codemode y en deferred." ;;

08) titulo 08 "Extensiones I"
    echo "  Extensiones: $EXT"
    for f in hola.ts tests.ts permisos.ts; do comprueba "existe extensiones/$f" "vuelve a sacarlo con git -C \"$EXT\" checkout -- $f" test -s "$EXT/$f"; done
    if command -v pi > /dev/null 2>&1; then
      cmds=$(pi_comandos "$EXT/hola.ts")
      if grep -qx hola <<< "$cmds"; then bien "Pi carga hola.ts y registra el comando /hola (comprobado con pi --mode rpc, sin modelo)"
      else mal "Pi carga hola.ts y registra el comando /hola" "prueba pi -e \"$EXT/hola.ts\" y mira el error; el comando se registra con pi.registerCommand(\"hola\", …)"; fi
      for f in tests.ts permisos.ts; do
        comprueba "Pi carga $f sin errores" "pi -e \"$EXT/$f\" enseña el error de carga" pi_carga "$EXT/$f"
      done
    else
      aviso "no encuentro pi: compruebo el código en vez de cargarlo"
      comprueba "hola.ts registra el comando hola" "usa pi.registerCommand(\"hola\", …)" grep -qE 'registerCommand\(\s*"hola"' "$EXT/hola.ts"
    fi
    comprueba "tests.ts registra la herramienta ejecutar_tests" "usa pi.registerTool({ name: \"ejecutar_tests\", … })" \
      sh -c "grep -q 'registerTool' \"$EXT/tests.ts\" && grep -q 'ejecutar_tests' \"$EXT/tests.ts\""
    comprueba "permisos.ts se engancha a tool_call y protege AGENTS.md" "el modo de aprobación va en pi.on(\"tool_call\", …), con AGENTS.md entre las rutas protegidas" \
      sh -c "grep -q 'tool_call' \"$EXT/permisos.ts\" && grep -q 'AGENTS.md' \"$EXT/permisos.ts\""
    if [ -n "${PI_CODING_AGENT_DIR:-}" ] && [ -e "$PI_CODING_AGENT_DIR/extensions/permisos.ts" ]; then
      aviso "sigue permisos.ts en $PI_CODING_AGENT_DIR/extensions: en el vídeo se quita al terminar"
    fi
    terminar ;;

09) titulo 09 "Extensiones II y paquetes"
    echo "  Extensiones: $EXT"
    comprueba "permisos.ts reconstruye su estado desde la rama (getBranch)" "recorre ctx.sessionManager.getBranch(), no getEntries(): es la versión rota del vídeo" \
      grep -q "getBranch" "$EXT/permisos.ts"
    comprueba "permisos.ts escucha session_tree" "sin pi.on(\"session_tree\", …) el estado no cambia al moverte con /tree" grep -q "session_tree" "$EXT/permisos.ts"
    comprueba "permisos.ts guarda sus decisiones en la sesión (appendEntry)" "usa pi.appendEntry(\"permisos\", …)" grep -q "appendEntry" "$EXT/permisos.ts"
    comprueba "hay package.json con la palabra clave pi-package y la lista pi.extensions" "mira el package.json del vídeo: keywords [\"pi-package\"] y pi.extensions" \
      node -e 'const p=require(process.argv[1]); const l=(p.pi&&p.pi.extensions)||[]; process.exit((p.keywords||[]).includes("pi-package") && l.length && l.every(f=>require("fs").existsSync(require("path").resolve(require("path").dirname(process.argv[1]),f))) ? 0 : 1)' "$EXT/package.json"
    if command -v pi > /dev/null 2>&1 && [ -f "$EXT/package.json" ]; then
      if grep -qx hola <<< "$(pi_comandos "$EXT")"; then bien "Pi carga la carpeta como paquete y aparece /hola (pi --mode rpc, sin modelo)"
      else mal "Pi carga la carpeta como paquete y aparece /hola" "prueba pi -e \"$EXT\" y mira el error"; fi
    fi
    terminar ;;

10) titulo 10 "Pi programático"
    s="${1:-$TIENDA/scripts/revisar.sh}"; echo "  Script: $s"
    comprueba "el script existe y es ejecutable" "chmod +x \"$s\"" test -x "$s"
    comprueba "no tiene errores de sintaxis (bash -n)" "bash -n \"$s\" te dice la línea" bash -n "$s"
    comprueba "ejecuta las pruebas por su cuenta, sin el modelo" "lo que se puede comprobar sin modelo, lo comprueba el script: npm test antes de llamar a Pi" grep -q "npm test" "$s"
    comprueba "llama a Pi en modo JSON" "pi -p --mode json, para guardar los eventos" grep -qE -- "--mode[ =]json" "$s"
    herr=$(grep -oE -- "(--tools|-t)[ =][a-z_,*]+" "$s" | head -1 | sed -E 's/^(--tools|-t)[ =]//')
    if [ -n "$herr" ]; then
      if ! grep -qE "(^|,)(edit|write|bash)(,|$)" <<< "$herr"; then bien "Pi va con herramientas de solo lectura ($herr)"
      else mal "Pi va con herramientas de solo lectura (ahora: $herr)" "en CI, nada de edit, write ni bash: --tools read,grep,find,ls"; fi
    elif grep -q "PI_TOOLS" "$s"; then
      aviso "las herramientas dependen de PI_TOOLS: en CI ejecútalo con PI_TOOLS=read,grep,find,ls"
    else
      mal "Pi va con herramientas de solo lectura" "añade --tools read,grep,find,ls (o una variable que lo fije en CI)"
    fi
    grep -q -- "--no-approve" "$s" || aviso "sin --no-approve, Pi cargaría las extensiones del proyecto que revisa"
    comprueba "carga la extensión de permisos como red de seguridad" "añade -e con tu permisos.ts" grep -qE -- "(-e|--extension)[ =][^ ]*permisos" "$s"
    comprueba "guarda el informe y los errores" "escribe el informe y los errores en ficheros para mirarlos después" sh -c "grep -q informe \"$s\" && grep -q errores \"$s\""
    if [ -f /tmp/csn/revision/informe.md ]; then
      comprueba "el último informe termina en VEREDICTO: OK o VEREDICTO: CAMBIOS" "el prompt pide esa última línea" \
        sh -c "tail -n 3 /tmp/csn/revision/informe.md | grep -qE 'VEREDICTO: (OK|CAMBIOS)'"
    fi
    terminar ;;

11) titulo 11 "De Pi a oh my pi"
    a_mano "La demo no cambia la tienda: git status debe salir limpio (si creaste .claude/commands, bórralo: rm -r .claude).
omp --profile demo config path: el perfil demo existe y tiene su config.yml y sus sesiones.
omp --profile demo config get tools.approvalMode: yolo (de fábrica).
Tu directorio de agente de Pi sigue intacto: no debe aparecer un settings.json.bak." ;;

12) titulo 12 "La TUI y las sesiones"
    a_mano "La demo no cambia la tienda: git status debe salir limpio.
En ~/.omp/profiles/demo/agent/sessions/ hay la sesión original, su fork y la de /new.
Con jq sobre la original: una entrada \"type\":\"label\" con umbral-50 y el título envio-umbrales." ;;

13) titulo 13 "Contexto y memoria"
    comprueba "src/ no ha cambiado: solo se tocan las pruebas" "git diff f27bfae -- src enseña el cambio; deshazlo con git restore src" sin_cambios f27bfae src
    comprueba "test/envio.test.js tiene cambios (el caso de 40 € y el subtotal negativo)" "pide el caso de exactamente 40 € y el de subtotal negativo" \
      sh -c "! git -C \"$TIENDA\" diff --quiet f27bfae -- test/envio.test.js"
    n=$(cuenta_pruebas)
    if [ "$n" -ge 17 ]; then bien "hay al menos 17 pruebas ($n), las 15 de partida y las dos nuevas"
    else mal "hay al menos 17 pruebas (hay $n)" "faltan el test de 40 € y el de subtotal negativo"; fi
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    echo "  A mano: /context antes y después, el resumen de /compact y lo que conserva /handoff (están en la sesión)."
    terminar ;;

14) titulo 14 "Modelos, roles y razonamiento"
    comprueba "gastosEnvio(subtotal, urgente) suma 2 € al envío normal" "pide el envío urgente (primer mensaje del vídeo)" \
      js "const {gastosEnvio:g}=await envio(); return igual(g(10,true),6.95) && igual(g(10),4.95)"
    comprueba "el recargo urgente se cobra también con el envío gratis" "«también cuando el envío es gratis»: gastosEnvio(60, true) debe dar 2" \
      js "const {gastosEnvio:g}=await envio(); return igual(g(60,true),2)"
    comprueba "totalConEnvio acepta urgente: 39,99 € urgente → 55,34 €" "segundo mensaje del vídeo: el test del carrito de 39,99 € con envío urgente" \
      js "const {totalConEnvio:t}=await carrito(); return igual(t([{precio:39.99,cantidad:1}],undefined,21,true),55.34)"
    comprueba "hay pruebas del envío urgente" "pide las pruebas del urgente" grep -qi "urgente" "$TIENDA/test/envio.test.js"
    if js "const {gastosEnvio:g}=await envio(); return igual(g(45),4.95)" 2>/dev/null; then
      bien "el umbral de envío gratis está en 50 € (tercer mensaje)"
      if pruebas_pasan > /dev/null 2>&1; then bien "npm test pasa (has actualizado las pruebas del umbral)"
      else aviso "npm test falla: es lo esperado tras el tercer mensaje («No toques los tests ni los ejecutes»); el advisor lo señala"; fi
    else
      aviso "el umbral sigue en 40 €: falta el tercer mensaje (sube el umbral a 50 € sin tocar los tests)"
      comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    fi
    terminar ;;

15) titulo 15 "Planificar y dirigir"
    a_mano "src/carrito.js acepta códigos de cupón: BIENVENIDA10 (10 % del subtotal) y ENVIOGRATIS (envío a cero), sin distinguir mayúsculas,
y un código desconocido da un error claro; la API de objeto { porcentaje } sigue funcionando.
git diff: solo cambian src/carrito.js y test/carrito.test.js, y el test que añadiste a mano en minúsculas sigue intacto.
node --test sale con 0. El plan guardado (CÓDIGOS_DE_CUPÓN_PLAN.md) queda sin seguimiento: bórralo o muévelo fuera antes de ./preparar.sh." ;;

16) titulo 16 "Subagentes y paralelo"
    comprueba "src/envio.js solo cambia en comentarios (JSDoc), no en el código" "el encargo era documentar sin cambiar el código: compara con git diff f27bfae -- src/envio.js" \
      node -e 'const fs=require("fs"),cp=require("child_process"); const q=s=>s.replace(/\/\*[\s\S]*?\*\//g,"").replace(/\/\/.*$/gm,"").replace(/\s+/g,"");
        const antes=cp.execFileSync("git",["-C",process.argv[1],"show","f27bfae:src/envio.js"]).toString(); const ahora=fs.readFileSync(process.argv[1]+"/src/envio.js","utf8");
        process.exit(q(antes)===q(ahora) && antes!==ahora ? 0 : 1)' "$TIENDA"
    comprueba "el umbral vuelve a estar en 40 € (lo deshizo /cleanse)" "el cambio a 45 € era para probar /cleanse --tests" grep -q "LIMITE_GRATIS = 40" "$TIENDA/src/envio.js"
    comprueba "las pruebas no han cambiado" "git diff f27bfae -- test" sin_cambios f27bfae test
    comprueba "el README explica cómo ejecutar los tests" "era el encargo de /tan" sh -c "! git -C \"$TIENDA\" diff --quiet f27bfae -- README.md && grep -qiE 'npm test|node --test' \"$TIENDA/README.md\""
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    if [ -f "$TIENDA/.omp/agents/revisor-tests.md" ]; then
      comprueba "el agente revisor-tests no tiene edit ni write" "en su frontmatter, tools: read, grep, glob, bash" \
        sh -c "! grep -E '^tools:' \"$TIENDA/.omp/agents/revisor-tests.md\" | grep -qE 'edit|write'"
    else aviso "no hay .omp/agents/revisor-tests.md (el agente propio del vídeo)"; fi
    terminar ;;

17) titulo 17 "El IDE integrado"
    comprueba "no queda ningún gastosEnvio en src ni en test (el cambio de nombre con lsp)" "grep -rn gastosEnvio src test" \
      sh -c "! grep -rqw gastosEnvio \"$TIENDA/src\" \"$TIENDA/test\""
    comprueba "envio.js exporta calcularEnvio y funciona igual" "aplica el rename de lsp y ejecuta los tests" \
      js "const {calcularEnvio:c}=await envio(); return igual(c(10),4.95) && c(40)===0"
    comprueba "carrito.js tiene una función redondear" "cuarto mensaje: ast_grep, ast_edit y después la función redondear" grep -qE "function redondear" "$TIENDA/src/carrito.js"
    comprueba "los redondeos a céntimos pasan por redondear" "solo debe quedar un Math.round en src/carrito.js, el de redondear" \
      test "$(grep -c 'Math.round' "$TIENDA/src/carrito.js")" -le 1
    comprueba "el cupón vuelve a descontar una sola vez (el fallo que se depura)" "usa la herramienta debug y arréglalo" \
      js "const {totalConCupon:t}=await carrito(); return igual(t([{precio:100,cantidad:1}],{porcentaje:10}),90)"
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    comprueba "datos/ sigue igual (es de solo lectura)" "git -C \"$RAIZ\" checkout -- datos" intacta datos
    terminar ;;

18) titulo 18 "Git, calidad y entrega"
    a_mano "El vídeo parte de un cambio sin commitear con un fallo sembrado que no está en los materiales.
Si lo reproduces: totalUrgente calcula el envío sin IVA (un carrito de 35 € urgente da 50,30 €) y hay prueba de ese caso.
git log -1: un commit «tienda: añade el envío urgente» con cuatro ficheros, sin el README.
git worktree list enseña el worktree de /wt, con su commit encima de demo-18. Al terminar: borra el worktree y la rama." ;;

19) titulo 19 "Aprobaciones, reglas y hooks"
    comprueba "hay .omp/config.yml y no está en yolo" "mkdir .omp && cp \"$RAIZ/omp-equipo/config.yml\" .omp/" \
      sh -c "grep -qE 'approvalMode: *(write|ask|always-ask)' \"$TIENDA/.omp/config.yml\""
    comprueba "está el hook de rutas protegidas en .omp/hooks/pre" "mkdir -p .omp/hooks/pre && cp \"$RAIZ/omp-equipo/rutas-protegidas.ts\" .omp/hooks/pre/" \
      test -s "$TIENDA/.omp/hooks/pre/rutas-protegidas.ts"
    comprueba "hay una regla del proyecto contra toFixed en .omp/rules" "créala con /omfg (elige «This project»)" \
      sh -c "grep -l 'toFixed' \"$TIENDA\"/.omp/rules/*.md"
    comprueba "AGENTS.md no ha cambiado (lo protege el hook)" "git diff f27bfae -- AGENTS.md; deshazlo con git checkout f27bfae -- AGENTS.md" sin_cambios f27bfae AGENTS.md
    comprueba "textoEnvio(subtotal) da los gastos como texto: 4,95 € y 0,00 €" "primer mensaje del vídeo" \
      js "const {textoEnvio:t}=await envio(); const n=s=>String(s).replace(/\s/g,' '); return n(t(10))==='4,95 €' && n(t(40))==='0,00 €'"
    comprueba "no queda ningún toFixed en src (la regla)" "redondea con Math.round(x * 100) / 100 y muestra con Intl.NumberFormat" \
      sh -c "! grep -rq 'toFixed' \"$TIENDA/src\""
    comprueba "npm test pasa" "ejecuta npm test y mira qué falla" pruebas_pasan
    [ -z "$(git -C "$TIENDA" remote)" ] || aviso "la tienda tiene un remoto: en el vídeo el push está en deny y no hay remoto"
    terminar ;;

20) titulo 20 "Extender oh my pi"
    comprueba "está el comando del proyecto .omp/commands/repaso.md" "mkdir -p .omp/commands && cp \"$RAIZ/omp-equipo/repaso.md\" .omp/commands/" \
      grep -q "^description:" "$TIENDA/.omp/commands/repaso.md"
    comprueba "está la skill en .agents/skills/notas-de-version" "mkdir -p .agents/skills && cp -r \"$RAIZ/skills/notas-de-version\" .agents/skills/" \
      test -s "$TIENDA/.agents/skills/notas-de-version/SKILL.md"
    comprueba "AGENTS.md no ha cambiado (lo protege permisos.ts cargado en omp)" "git checkout f27bfae -- AGENTS.md" sin_cambios f27bfae AGENTS.md
    comprueba "no hay commits nuevos (la demo solo mira)" "git log f27bfae..HEAD" test "$(git -C "$TIENDA" rev-list --count f27bfae..HEAD)" = 0
    terminar ;;

21) titulo 21 "omp programático, métricas y equipo"
    a_mano "La demo no cambia la tienda: git status debe salir limpio.
En /tmp/csn/omp21/revision/: informe.md termina en VEREDICTO: CAMBIOS y el script sale con 1 (el umbral de 50 € rompe tres pruebas).
Con la red de seguridad, errores.jsonl recoge «requires approval but no interactive UI available».
scripts/revisar-omp.sh y su workflow no están en los materiales: compáralo con scripts/revisar.sh del vídeo 10." ;;

22) titulo 22 "Diseñar tu harness"
    a_mano "medir/medir.sh deja un .juez por ejecución en /tmp/csn/r: cat /tmp/csn/r/*.juez (pasa/falla, ficheros tocados, redondeos).
medir/resumen.sh resume coste, turnos y resultado por configuración.
La tienda sigue en master y limpia: git -C ~/csn/tienda status. Al terminar: medir/limpiar.sh." ;;

23) titulo 23 "El repo como sistema de registro"
    comprueba "funcionalidades.json es JSON válido" "git diff funcionalidades.json enseña qué se rompió" node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$TIENDA/funcionalidades.json"
    comprueba "ninguna funcionalidad está en pasa sin evidencias" "pasa exige la verificación ejecutada y anotada en evidencias" \
      node -e 'const f=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).funcionalidades; process.exit(f.some(x=>x.estado==="pasa"&&!(x.evidencias||[]).length)?1:0)' "$TIENDA/funcionalidades.json"
    comprueba "como mucho una funcionalidad en curso" "una tarea cada vez" \
      node -e 'const f=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).funcionalidades; process.exit(f.filter(x=>x.estado==="en_curso").length<=1?0:1)' "$TIENDA/funcionalidades.json"
    e1=$(estado_de ticket-001)
    if [ "${e1%% *}" = pasa ]; then bien "ticket-001 está en pasa ($e1 evidencia(s))"; else mal "ticket-001 está en pasa (está en ${e1%% *})" "«Trabaja en la siguiente funcionalidad.»"; fi
    if (cd "$TIENDA" && node -e 'process.exit(JSON.parse(require("fs").readFileSync("funcionalidades.json","utf8")).funcionalidades.some(x=>x.estado==="en_curso")?0:1)'); then
      comprueba "hay una funcionalidad a medias y traspaso.md explica dónde se quedó" "al cortar una sesión, el agente deja el traspaso escrito" test -s "$TIENDA/traspaso.md"
    else
      comprueba "nada a medias y traspaso.md vacío" "si no queda nada a medias, el traspaso se vacía" test ! -s "$TIENDA/traspaso.md"
    fi
    comprueba "progreso.md tiene las sesiones" "cada sesión anota lo que hizo en progreso.md" sh -c "! git -C \"$TIENDA\" diff --quiet 35e712c -- progreso.md"
    comprueba "./init.sh sale con 0" "./init.sh te dice qué falla" sh -c "cd \"$TIENDA\" && ./init.sh"
    comprueba "todo está commiteado (git status limpio)" "el estado vive en el repositorio: haz commit" limpia
    terminar ;;

24) titulo 24 "Verificar de verdad"
    necesita_etiqueta rubrica-ticket-003
    comprueba "existe ./verificar.sh y es ejecutable" "git checkout rubrica-ticket-003 -- verificar.sh" test -x "$TIENDA/verificar.sh"
    comprueba "no se han tocado la rúbrica, la aceptación ni verificar.sh" "quien hace el trabajo no cambia la verificación: git checkout rubrica-ticket-003 -- rubricas aceptacion verificar.sh" \
      sin_cambios 3a36c10 rubricas aceptacion verificar.sh
    e=$(estado_de ticket-003)
    if [ "${e%% *}" = pasa ] && [ "${e#* }" -gt 0 ]; then bien "ticket-003 está en pasa con evidencias ($e)"
    else mal "ticket-003 está en pasa con evidencias (está: $e)" "la puerta solo deja marcar pasa si ./verificar.sh ticket-003 pasa"; fi
    verificar_sale_0 ticket-003
    verificar_sale_0
    terminar ;;

25) titulo 25 "Bucles, grafos y el coste de orquestar"
    necesita_etiqueta rubrica-ticket-004
    comprueba "no se han tocado la rúbrica, la aceptación ni verificar.sh desde rubrica-ticket-004" "git checkout rubrica-ticket-004 -- rubricas aceptacion verificar.sh (¿partes de cuadre, con la aceptación v1?)" \
      sin_cambios 0ad4487 rubricas aceptacion verificar.sh
    e=$(estado_de ticket-004)
    if [ "${e%% *}" = pasa ] && [ "${e#* }" -gt 0 ]; then bien "ticket-004 está en pasa con evidencias ($e)"
    else mal "ticket-004 está en pasa con evidencias (está: $e)" "/loop 3 --until './verificar.sh ticket-004' … hasta que pase"; fi
    verificar_sale_0 ticket-004
    oculta_pasa ticket-004
    terminar ;;

26) titulo 26 "Proyecto final"
    necesita_etiqueta rubrica-ticket-005
    comprueba "no se han tocado la rúbrica, la aceptación ni verificar.sh" "git checkout rubrica-ticket-005 -- rubricas aceptacion verificar.sh" \
      sin_cambios 6ff1952 rubricas aceptacion verificar.sh
    e=$(estado_de ticket-005)
    if [ "${e%% *}" = pasa ] && [ "${e#* }" -gt 0 ]; then bien "ticket-005 está en pasa con evidencias ($e)"
    else mal "ticket-005 está en pasa con evidencias (está: $e)" "implementa con Pi y la puerta: pi -e \"$EXT/puerta.ts\""; fi
    verificar_sale_0 ticket-005
    verificar_sale_0
    oculta_pasa ticket-005
    comprueba "todo está commiteado (git status limpio)" "haz commit: la puerta ejecuta ./verificar.sh antes" limpia
    terminar ;;

27) titulo 27 "De fallos a regresiones"
    a_mano "regresiones/juez.sh casos/revision-borde-cupon.json calibracion/bueno.md da PASA, y con malo.md, FALLA.
regresiones/resumen-regresiones.sh: una fila por ejecución, y por caso, si pasó alguna vez y si pasó todas.
Mira en cada sesión qué modelo respondió de verdad (jq -r '.message.model' resultados/<caso>/<tanda>-<n>/sesion/*.jsonl)." ;;

28) titulo 28 "Agentes que trabajan sin ti"
    necesita_etiqueta rubrica-ticket-006
    comprueba "existe la rama robot" "./preparar.sh vuelve a traer las ramas de la tienda" git -C "$TIENDA" rev-parse -q --verify refs/heads/robot
    comprueba "el perfil robot de oh my pi está instalado" "cp $RAIZ/robot/perfil/config.yml ~/.omp/profiles/robot/agent/config.yml" \
      test -f "$HOME/.omp/profiles/robot/agent/config.yml"
    a_mano "robot/resumen-robot.sh: una fila por ejecución y lo gastado hoy. Una entrega deja la rama robot-ticket-006-…
en el remoto revision (git -C ~/csn/remoto/tienda.git branch) y la petición en robot/registro/<id>.pr.txt.
Prueba el receptor sin lanzar nada: sin token da 401, con {\"ticket\":\"borra todo\"} da 400." ;;

*) echo "No hay vídeo $v en el curso (01-28)."; exit 2 ;;
esac
