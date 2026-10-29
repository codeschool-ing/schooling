---
title: Offline
version: 1
---

**O único teste honesto de uma estratégia offline é a rede desligada.** O `tools/offline.ts` abre o primeiro
endereço que recebe, espera o worker ficar pronto e o abre de novo, porque **um service worker controla as
páginas abertas depois de ser instalado, não a página que o instalou**. Depois ele tira o navegador da rede e
abre cada endereço, dizendo o que cada página mostrou no título e de onde veio cada resposta. Salve-o em
`tools/`:

```typescript
// tools/offline.ts: open a page so its service worker installs, open it again so the worker
// controls it, then take the browser off the network and open pages, saying for each what
// it showed and where every response came from.
//
//   node tools/offline.ts URL [URL...]    (the first is visited online; all are opened offline)
import { chromium } from "playwright";

const urls = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();
await page.goto(urls[0], { waitUntil: "networkidle" });
await page.evaluate(() => navigator.serviceWorker.ready);
// A worker controls the pages opened after it was installed, not the one that installed it.
await page.reload({ waitUntil: "networkidle" });
await context.setOffline(true);
for (const url of urls) {
  const served = new Set<string>();
  const log = (r: import("playwright").Response) =>
    served.add(`${new URL(r.url()).pathname} ${r.status()} ${r.fromServiceWorker() ? "from the service worker" : "from the network"}`);
  page.on("response", log);
  try {
    await page.goto(url, { waitUntil: "load" });
    console.log(`${url}: "${await page.textContent("h1")}"`);
  } catch (e) {
    console.log(`${url}: ${(e as Error).message.split("\n")[0]}`);
  }
  page.off("response", log);
  for (const line of served) console.log(`  ${line}`);
}
await browser.close();
```

Visite o curso de Git, e depois tente ele, um curso nunca aberto, e a página de estatísticas, todos offline:

```
ana@dev:~/planner$ node tools/offline.ts http://localhost:3000/courses/git http://localhost:3000/courses/javascript http://localhost:3000/stats
http://localhost:3000/courses/git: "Git"
  /courses/git 200 from the service worker
  /assets/index-DKDcq93q.js 200 from the service worker
  /assets/planner-BNdUlffC.js 200 from the service worker
  /fonts/plex-400.woff2 200 from the service worker
  /covers/git-800.avif 200 from the service worker
  /fonts/plex-700.woff2 200 from the service worker
http://localhost:3000/courses/javascript: "You are offline"
  /courses/javascript 200 from the service worker
http://localhost:3000/stats: "You are offline"
  /stats 200 from the service worker
```

**O curso de Git abriu sem rede nenhuma**, cada arquivo vindo do worker: a página da última cópia, os scripts do
cache, a capa e as fontes dos deles. **Os outros dois mostraram a página offline**, que é o último recurso da
estratégia network first, e melhor que o erro do próprio navegador, porque diz o que aconteceu e aponta para o que
funciona.

## O que funciona offline sem nunca ter sido buscado

**Com a página de Git aberta, o resto do planner também funciona offline**: um clique em *All courses* desenha a
página inicial a partir do plano que está na página, sem requisição, como a decisão da aula 8 o manteve. A página
que precisa da rede é a que o navegador carrega, e um planner que navega sozinho precisa disso uma vez só. A página
de estatísticas é a exceção: o gráfico dela é um chunk carregado sob demanda, então offline ela precisa ter sido
aberta uma vez online para o chunk estar no cache.

## O que custa online

**Toda requisição de uma página controlada passa por um script primeiro.** Um worker que o navegador parou, o que
ele faz quando um site fica ocioso, precisa ser iniciado antes de responder, e num celular lento isso pode custar
dezenas de milissegundos antes do primeiro byte de uma página. Os navegadores conseguem começar a requisição da
própria página em paralelo com o worker, um recurso chamado navigation preload, que um worker liga no evento
`activate`. Numa visita repetida a troca ainda é boa: os scripts, as fontes e a capa chegam sem ida e volta, o que
os 304 da aula 9 não conseguiam.
