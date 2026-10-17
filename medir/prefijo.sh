#!/usr/bin/env bash
# Cuánto pesa cada roster antes de trabajar: tokens de entrada de «Di solo: hola».
export PI_CODING_AGENT_DIR=/tmp/csn/pi-agent OMP_PROFILE=demo
cd ~/csn/tienda
tokens() { jq -r 'select(.type=="message_end" and .message.role=="assistant")
                  | .message.usage | .input + .cacheRead + .cacheWrite' | head -1; }
fila() { printf '%-34s %6s\n' "$1" "$2"; }

fila "pi  sin herramientas"         "$(pi -p --mode json --no-session --no-mcp --no-skills --no-tools 'Di solo: hola' | tokens)"
fila "pi  read,bash"                "$(pi -p --mode json --no-session --no-mcp --no-skills -t read,bash 'Di solo: hola' | tokens)"
fila "pi  las cuatro de serie"      "$(pi -p --mode json --no-session --no-mcp --no-skills 'Di solo: hola' | tokens)"
fila "pi  las siete integradas"     "$(pi -p --mode json --no-session --no-mcp --no-skills -t read,bash,edit,write,grep,find,ls 'Di solo: hola' | tokens)"
fila "pi  serie + codemode"         "$(pi -p --mode json --no-session --no-mcp --no-skills -t +codemode 'Di solo: hola' | tokens)"
fila "omp read,bash,edit,write"     "$(omp -p --mode json --no-session --tools read,bash,edit,write 'Di solo: hola' | tokens)"
fila "omp todas, con catálogo xd://" "$(omp -p --mode json --no-session 'Di solo: hola' | tokens)"
fila "omp todas, sin catálogo"      "$(omp -p --mode json --no-session --config ~/csn/medir/xdev-off.yml 'Di solo: hola' | tokens)"
