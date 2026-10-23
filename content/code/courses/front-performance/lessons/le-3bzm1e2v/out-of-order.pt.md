---
title: O que o navegador faz com os pedaços
version: 1
---

**O navegador desenhou o primeiro pedaço sem esperar o segundo.** É isso que faz o streaming valer a
pena, e é fácil conferir: o `tools/appear.ts` abre uma página no Chromium e registra quando cada
pedaço de texto de que ele foi avisado apareceu pela primeira vez na tela. Salve em `tools/`:

```typescript
// tools/appear.ts: open a page in Chromium and say when each piece of text
// first appeared on the screen, in milliseconds after the request.
//
//   node tools/appear.ts URL TEXT...   [--no-js]
import { chromium } from "playwright";

const args = process.argv.slice(2);
const js = !args.includes("--no-js");
const [url, ...texts] = args.filter((a) => a !== "--no-js");
const browser = await chromium.launch();
const page = await browser.newPage({ javaScriptEnabled: js });
await page.addInitScript((wanted: string[]) => {
  const seen: Record<string, number> = {};
  (window as any).seen = seen;
  const check = () => {
    for (const t of wanted) if (!(t in seen) && document.body?.innerText.includes(t)) seen[t] = Math.round(performance.now());
  };
  new MutationObserver(check).observe(document, { childList: true, subtree: true, characterData: true });
}, texts);
await page.goto(url, { waitUntil: "load" });
await page.waitForTimeout(300);
const seen = js ? await page.evaluate(() => (window as any).seen) : {};
for (const t of texts) console.log(`${js ? (t in seen ? `${String(seen[t]).padStart(5)} ms` : "  never ") : "     -  "}  ${t}`);
if (!js) console.log((await page.locator("body").innerText()).trim());
await browser.close();
```

Ele observa com um `MutationObserver`, o aviso do próprio navegador de que o documento mudou, então vê
o texto conforme o parser o acrescenta, antes de a página terminar de carregar. Com `--no-js` ele não
consegue rodar o seu observador, e imprime o texto da página no final.

```
ana@dev:~/planner$ node tools/appear.ts http://localhost:3005/courses/git Git "Loading sessions" 2026-10-24
   19 ms  Git
   19 ms  Loading sessions
 1010 ms  2026-10-24
ana@dev:~/planner$ node tools/appear.ts http://localhost:3005/courses/git Git "Loading sessions" 2026-10-24 --no-js
     -    Git
     -    Loading sessions
     -    2026-10-24
All courses

Git
Loading sessions…
```

**O título e o marcador estavam na tela um segundo antes das sessões.** Uma página que esperasse a sua
consulta mais lenta não teria mostrado nada durante esse segundo.

## Fora de ordem

As sessões chegaram por último, mas não ficam no fim da página: elas pertencem ao meio, à lista. O
servidor não podia mandá-las no lugar delas, porque o HTML depois delas, o fim da lista e do `<main>`,
já tinha ido. Então ele as mandou **fora de ordem**, no fim da resposta, dentro de um `<template>` que
o navegador interpreta e não mostra, e uma linha de script as moveu para onde pertencem. O streaming do
React faz o mesmo com mais cuidado: um elemento escondido por fronteira e uma pequena função que troca
cada um, que é o `<div hidden id="S:0">` que você vai ver o Next.js mandar duas seções adiante.

**A troca é JavaScript, e sem JavaScript ela nunca acontece**: o marcador fica, e as sessões ficam num
template que ninguém mostra. A segunda execução, com o JavaScript desligado, mostra exatamente isso. O
streaming em ordem, em que cada pedaço é mandado no seu lugar assim que tudo antes dele está pronto,
funciona sem script nenhum, e é o que um servidor faz quando a parte lenta fica no fim da página.
