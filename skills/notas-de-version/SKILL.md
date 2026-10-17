---
name: notas-de-version
description: Redacta notas de versión a partir del historial de git. Úsala cuando pidan notas
  de versión, un changelog o un resumen de lo que ha cambiado entre dos puntos.
---
1. Ejecuta `git log --oneline` desde el punto indicado (por defecto, los 10 últimos commits).
2. Agrupa en «Novedades», «Correcciones» y «Pruebas»; omite los grupos vacíos.
3. Cada punto en una línea, en español y sin hashes.
4. Termina con una línea: «Incluye N commits».
