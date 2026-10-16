# Traspaso

## ticket-002 · Línea de ticket (en curso)

- Ya hecho: `lineaTicket({ nombre, precio, cantidad })` en `src/ticket.js`. Formato verificado a mano:
  `{ nombre: 'Taza', precio: 4.5, cantidad: 2 }` → `"2 x Taza  4,50 € = 9,00 €"`.
- Pendiente: añadir la prueba en `test/ticket.test.js` (casos de una y varias unidades, redondeo a céntimos) y
  ejecutar `node --test test/ticket.test.js` para poder marcar `ticket-002` como `pasa`.
- No se ha tocado la verificación de `funcionalidades.json`.
