---
title: Uma falha de release, lida com um source map
version: 1
---

**O quarto tipo de bug de release são dados que o desenvolvedor nunca teve.** Suponha que o servidor do
planner seja publicado de novo com `sessions` renomeado para `items`. Todo development build, contra o
servidor do próprio desenvolvedor, continua funcionando. Todo app publicado encontra o servidor novo. Este
programa faz o papel desse servidor: responde ao pedido do plano com o campo renomeado e imprime o que a tela
mostra, o erro, e a primeira linha da pilha que aponta para o código do app. Salve o `crash.mjs`:

```javascript
// crash.mjs: hand the planner a plan in a shape it does not expect, as a server deployed with a renamed
// field would, and print what the screen says and the first place the stack points at.
//
//   node crash.mjs URL
import { chromium } from "playwright";

const [url] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const logged = [];
page.on("console", (m) => m.type() === "error" && logged.push(m.text()));
// "sessions" renamed to "items" on the server, and nobody told the app
await page.route("**/plan", (route) =>
  route.fulfill({ json: { courses: [], items: [] }, headers: { "access-control-allow-origin": "*" } }),
);
await page.goto(url);
console.log("screen:", await page.getByText(/^Something went wrong|^The plan could not be loaded/).innerText());
const report = logged.find((t) => t.startsWith("render failed:"));
if (report) {
  console.log("error: ", report.split("\n")[0]);
  console.log("stack: ", report.split("\n").find((l) => l.includes("/_expo/static/js/"))?.trim());
}
await browser.close();
```

O `page.route` responde a uma requisição no próprio navegador, antes de ela sair, que é como um teste finge
ser um servidor que não controla. Exporte o build web com `--source-maps`, que escreve um arquivo `.map` ao
lado de cada bundle, e sirva-o:

```
ana@dev:~/planner$ node crash.mjs 'http://localhost:8082/?today=2026-10-21'
screen: Something went wrong on this screen. Your sessions are safe.
error:  render failed: Cannot read properties of undefined (reading 'filter') 
stack:  at e.weekTotal (http://localhost:8082/_expo/static/js/web/index-3779a6eed14c6112750693ef8e942cf2.js:1324:820)
```

**A boundary segurou**: a tela diz que algo deu errado, e não nada. O erro é um `TypeError` sobre `filter`,
e a pilha diz onde: linha 1324, coluna 820, de um arquivo que é o app inteiro espremido em algumas centenas
de linhas muito longas. Esse lugar não quer dizer nada para uma pessoa.

## O mapa de volta

**Um source map é a tabela de cada lugar do bundle para o lugar do código de onde ele veio**, que o Metro
escreve enquanto constrói. O Node.js consegue ler um sem pacote nenhum. Salve o `whereis.mjs`:

```javascript
// whereis.mjs: turn a place in the minified web bundle, as a stack trace prints it, back into the
// source file, line and name, with the bundle's source map and Node's own reader for them.
//
//   node whereis.mjs DIST index-….js:LINE:COLUMN
import { readFileSync } from "node:fs";
import { SourceMap } from "node:module";

const [dist, at] = process.argv.slice(2);
const [file, line, column] = at.split(":");
const map = new SourceMap(JSON.parse(readFileSync(`${dist}/_expo/static/js/web/${file}.map`, "utf8")));
const origin = map.findOrigin(Number(line), Number(column));
console.log(`${origin.fileName}:${origin.lineNumber}:${origin.columnNumber}`, origin.name ? `(${origin.name})` : "");
```

Dê a ele a posição exatamente como a pilha a imprimiu:

```
ana@dev:~/planner$ node whereis.mjs dist index-3779a6eed14c6112750693ef8e942cf2.js:1324:820
/src/planner.ts:30:30 (filter)
ana@dev:~/planner$ sed -n 30p src/planner.ts
  const week = plan.sessions.filter((s) => s.date >= monday && s.date < last);
```

**O `src/planner.ts`, linha 30**, a primeira linha do `weekTotal`, filtrando `plan.sessions`, que não existe
mais. Um relatório de falha de um app publicado é essa posição minificada e mais nada, então **todo release
guarda os seus source maps**, num lugar onde o time os encontra e nunca servidos aos usuários. Serviços de
relatório de falhas como o Sentry os recebem na hora do build e fazem essa consulta para cada relatório que
chega.
