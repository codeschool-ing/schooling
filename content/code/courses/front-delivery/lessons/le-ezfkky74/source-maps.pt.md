---
title: Source maps
version: 1
---

**Um source map é um arquivo que registra, para cada posição de um arquivo construído, o arquivo, a linha
e a coluna de onde ela veio.** Os bundlers os escrevem para as ferramentas de desenvolvedor do navegador,
que os usam para mostrar o código original durante a depuração. Um serviço de monitoramento os usa do
mesmo jeito, sobre uma pilha que chegou do navegador de outra pessoa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Um source map liga posições. O arquivo construído index.js tem uma linha comprida, e a posição linha 1, coluna 5016 nele fica dentro da função que o build renomeou para A. O map registra que essa posição veio de src/main.ts, linha 16, coluna 45, onde o código do próprio planner lança o erro.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que o navegador rodou</text><rect x=\"20\" y=\"32\" width=\"300\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">index-BzxC4LxE.js</text><text x=\"32\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">function A(){if(location.search…</text><text x=\"170\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1:5016</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que a equipe escreveu</text><rect x=\"400\" y=\"32\" width=\"300\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">src/main.ts</text><text x=\"412\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">if (location.search === \"?bug\")</text><text x=\"550\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">16:45</text><rect x=\"220\" y=\"132\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">index-BzxC4LxE.js.map</text><line x1=\"200\" y1=\"116\" x2=\"222\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"498\" y1=\"140\" x2=\"520\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,116.0 517.3,123.5 512.7,119.3\" fill=\"var(--paper-dim)\"></polygon></svg>", "caption": "O map é a única coisa que conhece as duas posições, e por isso precisa ser o map do mesmo build."}
```

O `build: { sourcemap: "hidden" }` no `vite.config.ts` pediu maps, e a palavra *hidden* é a parte que
importa. O Vite escreve os arquivos `.map` e deixa de fora o comentário que diria a um navegador onde
encontrá-los:

```
ana@dev:~/planner$ tail -c 120 dist/assets/index-*.js; echo; ls dist/assets/
)}),window.addEventListener(`popstate`,A),o(E,e=>{({courses:O,sessions:k}=e),A()}).catch(e=>u(e,`load`));export{u as t};
apollo-C4i3kjo7.js
apollo-C4i3kjo7.js.map
index-BU4yu1tj.css
index-BzxC4LxE.js
index-BzxC4LxE.js.map
```

O arquivo construído termina sem uma linha `//# sourceMappingURL=`, então nenhum navegador pede o map. **Um
map guarda o código original, comentários e tudo**, no seu `sourcesContent`. Um map publicado ao lado do
site entrega a qualquer pessoa o TypeScript do planner como a equipe o escreveu, o que pouco importa para
um planner de estudos e importa muito para um código que guarda a lógica de um negócio, ou um comentário
que ninguém pretendia publicar.

## Fora do host público

Os maps são para a equipe, então saem de `dist/` antes de `dist/` ir para qualquer lugar. Uma pasta por
release guarda os maps de todo build que ainda possa estar rodando numa aba aberta de alguém:

```
ana@dev:~/planner$ release=$(git rev-parse --short HEAD); mkdir -p maps/$release && mv dist/assets/*.map maps/$release/ && ls maps/$release
apollo-C4i3kjo7.js.map
index-BzxC4LxE.js.map
```

O `maps/` está no `.gitignore` junto com os relatórios. Num pipeline de verdade, os maps vão para o serviço
de monitoramento, ou para o armazenamento do próprio pipeline ao lado do build, nunca para a pasta que o
host serve.

## Desfazendo uma pilha

O Node lê um source map sem pacote nenhum: o `SourceMap`, em `node:module`, recebe o JSON de um map e
responde `findOrigin(line, column)` com o arquivo, a linha e a coluna originais. Este script lê uma pilha,
acha o map do arquivo de cada frame e imprime o frame como ele foi escrito:

```javascript
// api/symbolicate.mjs: node api/symbolicate.mjs MAPS_FOLDER < a stack trace
import { readFileSync } from "node:fs";
import { SourceMap } from "node:module";
import { relative, resolve } from "node:path";

const folder = process.argv[2];
const maps = new Map();

for (const line of readFileSync(0, "utf8").trimEnd().split("\n")) {
  const frame = /([^/\s(]+\.js):(\d+):(\d+)/.exec(line);
  if (!frame) {
    console.log(line);
    continue;
  }
  const [, file, row, column] = frame;
  if (!maps.has(file)) maps.set(file, new SourceMap(JSON.parse(readFileSync(`${folder}/${file}.map`, "utf8"))));
  const origin = maps.get(file).findOrigin(Number(row), Number(column));
  const source = relative(process.cwd(), resolve(folder, origin.fileName));
  console.log(`    at ${source}:${origin.lineNumber}:${origin.columnNumber}`);
}
```

```
ana@dev:~/planner$ tail -1 api/errors.jsonl | node -e 'process.stdin.on("data", (d) => console.log(JSON.parse(d).stack))' | node api/symbolicate.mjs maps/$(git rev-parse --short HEAD)
Error: A bug, on purpose
    at src/main.ts:16:45
    at src/main.ts:56:3
    at src/apollo.ts:30:5
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:96:33
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:63:26
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:34:18
    at node_modules/@apollo/client/utilities/internal/filterMap.js:17:28
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:96:33
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:63:26
    at node_modules/rxjs/dist/esm5/internal/Subscriber.js:34:18
```

**`src/main.ts`, linha 16, coluna 45**: o bug. A linha 56 é a chamada ao `render` no callback que o `watch`
deu ao Apollo, a linha 30 do `apollo.ts` é o `watchPlanner` chamando esse callback, e todo o resto abaixo é
o RxJS entregando a resposta do cache. Um serviço hospedado faz exatamente isso para cada relatório, com os
maps que recebeu, e agrupa os relatórios pela linha para a qual eles apontam.

Tire o bug:

```
ana@dev:~/planner$ git restore src/main.ts
ana@dev:~/planner$ git status --short
?? api/symbolicate.mjs
```
