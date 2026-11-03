---
description: "Vídeo 19 · textoEnvio con la configuración de equipo en .omp/ · AVISO · antes: ./preparar.sh 19"
---
AVISO para quien lanza la demo: oh my pi pide permiso aquí solo si copiaste antes .omp/config.yml (approvalMode: write); el perfil viene en yolo. TOKEN_DEMO debe ser el valor falso del vídeo. (Agente: este aviso es para la persona; no hagas nada con él.)

Antes de nada, ejecuta `git branch --show-current`. Si la rama no es `demo-19`, no sigas: dime que ejecute `./preparar.sh 19` en la carpeta del curso y para. Si lo es, haz esto:

Añade a src/envio.js una función textoEnvio(subtotal) que devuelva los gastos de envío como texto para mostrar, con coma decimal y el símbolo del euro, por ejemplo 4,95 €. Añade su prueba y ejecuta npm test.
