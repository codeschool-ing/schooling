---
title: Um arquivo para toda página
version: 1
---

**O Vite constrói o planner num arquivo JavaScript só**, e toda página carrega ele inteiro: a página de
curso, a inicial, e qualquer página acrescentada depois. O build diz o tamanho:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 9 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.69 kB │ gzip: 0.35 kB
dist/assets/index-gserWk4t.css   0.76 kB │ gzip: 0.41 kB
dist/assets/index-yh2nfJj3.js   18.08 kB │ gzip: 6.95 kB

✓ built in 192ms
```

Dezoito kilobytes, sete pela rede. Para três páginas está ótimo, e continuaria ótimo se o planner nunca
crescesse. Páginas crescem, e o que decide se um arquivo só ainda é o certo não é o tamanho dele, e sim
**quanto dele uma página usa**.

## Quanto uma página roda

O Chromium consegue dizer, para cada script, que partes dele rodaram. Nas ferramentas de desenvolvedor
isso é o painel **Coverage**, no menu de mais ferramentas: recarregue com ele gravando, e cada script é uma
linha com o tamanho e a parte que nunca rodou, em vermelho. O `tools/unused.ts` faz a mesma pergunta a
partir de um programa. Salve-o em `tools/`:

```typescript
// tools/unused.ts: load a page and say, for each script it downloaded, how much of
// it ever ran: the Coverage panel of the browser's developer tools, as a program.
//
//   node tools/unused.ts URL
import { chromium } from "playwright";

const browser = await chromium.launch();
const page = await browser.newPage();
await page.coverage.startJSCoverage();
await page.goto(process.argv[2], { waitUntil: "networkidle" });
const entries = await page.coverage.stopJSCoverage();
await browser.close();

for (const entry of entries.filter((e) => e.url.includes("/assets/"))) {
  // V8 reports ranges with how often each ran, inner ranges inside outer ones. Applied
  // from the outermost in, each character ends up marked by the innermost range around it.
  const ran = new Uint8Array(entry.source!.length);
  const ranges = entry.functions.flatMap((f) => f.ranges)
    .sort((a, b) => a.startOffset - b.startOffset || b.endOffset - a.endOffset);
  for (const r of ranges) ran.fill(r.count > 0 ? 1 : 0, r.startOffset, r.endOffset);
  const used = ran.reduce((sum, x) => sum + x, 0);
  const kb = (n: number) => `${(n / 1024).toFixed(1)} KB`;
  console.log(`${new URL(entry.url).pathname.padEnd(30)} ${kb(ran.length).padStart(8)}, ran ${kb(used).padStart(8)} (${Math.round(100 * used / ran.length)}%)`);
}
```

O comentário do meio é a única parte sutil. O V8, o motor JavaScript do Chromium, informa um intervalo para
cada função e para cada bloco dentro de uma função que não rodou, e um bloco que não rodou pode estar dentro
de uma função que rodou. Ordenar os intervalos de fora para dentro, e deixar cada um sobrescrever o que
cobre, deixa cada caractere marcado pelo intervalo mais interno em volta dele.

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/courses/git
/assets/index-yh2nfJj3.js       17.7 KB, ran   8.2 KB (46%)
```

**Menos da metade do script do planner roda numa página de curso.** Isso é normal e inofensivo: o resto é o
desenho da página inicial, os tratadores de cliques que ainda não aconteceram, o código de uma divergência
que não ocorreu. Uma parte dessas não é motivo para dividir nada. O que seria é uma parte grande de um
arquivo grande, e a próxima seção faz um.
