# Revisar una validación nueva

Antes de aprobar un cambio que añade una validación, recorre una a una las entradas límite contra la condición exacta
que escribió el código, no contra lo que dice el comentario: la propiedad ausente, la propiedad presente con valor
`undefined`, `null`, `NaN`, `0`, un negativo, `Infinity` y una cadena. Para cada una, di qué camino del código toma y
qué devuelve. Si alguna se escapa de la validación que pide la especificación, es un defecto, aunque las pruebas pasen.
