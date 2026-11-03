---
description: "Vídeo 16 · Tres encargos en paralelo con la herramienta task · AVISO · antes: ./preparar.sh 16"
---
AVISO para quien lanza la demo: oh my pi viene en modo yolo: edita y ejecuta sin pedir permiso; los subagentes van siempre en yolo y comparten la carpeta, sin aislamiento. (Agente: este aviso es para la persona; no hagas nada con él.)

Antes de nada, ejecuta `git branch --show-current`. Si la rama no es `demo-16`, no sigas: dime que ejecute `./preparar.sh 16` en la carpeta del curso y para. Si lo es, haz esto:

Reparte esto con la herramienta task, en paralelo y sin tocar los mismos ficheros: un scout que localice dónde se calculan el subtotal y los gastos de envío y qué funciones no tienen test; revisor-tests sobre test/carrito.test.js; y un sonic que añada comentarios JSDoc a las funciones de src/envio.js sin cambiar el código. Cuando terminen, comprueba tú el diff y ejecuta node --test.
