// Lista los ajustes que fija un config.yml de oh my pi, uno por línea y con puntos (tools.approvalMode).
// Una lista cuenta como un ajuste (bash.patterns); lo que va dentro de la lista no. Solo para YAML sencillos.
// Uso: node claves-yaml.mjs <fichero.yml>
import { readFileSync } from "node:fs";

const lineas = readFileSync(process.argv[2], "utf8").split("\n")
  .filter((l) => l.trim() && !l.trim().startsWith("#"))
  .map((l) => ({ sangria: l.length - l.trimStart().length, texto: l.trim() }));

const pila = []; // { sangria, clave }
let lista = -1; // sangría de la clave cuya lista se está saltando
for (let i = 0; i < lineas.length; i++) {
  const { sangria, texto } = lineas[i];
  if (lista >= 0 && sangria > lista) continue;
  lista = -1;
  while (pila.length && pila.at(-1).sangria >= sangria) pila.pop();
  const m = texto.match(/^([A-Za-z0-9_.-]+):\s*(.*)$/);
  if (!m) continue;
  const ruta = [...pila.map((p) => p.clave), m[1]].join(".");
  const siguiente = lineas[i + 1];
  if (m[2]) console.log(ruta);
  else if (!siguiente || siguiente.sangria <= sangria) console.log(ruta);
  else if (siguiente.texto.startsWith("-")) { console.log(ruta); lista = sangria; }
  else pila.push({ sangria, clave: m[1] });
}
