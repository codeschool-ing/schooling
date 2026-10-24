---
title: Uma segunda visita, medida
version: 1
---

**O `tools/revisit.ts` carrega uma página, e depois a carrega de novo no mesmo navegador**, do jeito que um
visitante volta, e diz para cada requisição da segunda visita qual das três coisas aconteceu. Salve-o em
`tools/`:

```typescript
// tools/revisit.ts: load a page, then load it again in the same browser, as a
// visitor coming back, and say how each request of the second visit was answered:
// from the cache without asking, with a 304 that let the browser keep its copy, or
// downloaded again.
//
//   node tools/revisit.ts URL
import { chromium } from "playwright";

const url = process.argv[2];
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url, { waitUntil: "networkidle" });

// The DevTools protocol says what the page's own API does not: whether a request reached the
// network at all, and the status the server really sent, which for a 304 is not the one the page sees.
const cdp = await page.context().newCDPSession(page);
await cdp.send("Network.enable");
const rows = new Map<string, { path: string; cached: boolean; status?: number }>();
cdp.on("Network.requestWillBeSent", (e) => {
  // A data: address is part of the page, not a request to anybody.
  if (e.request.url.startsWith("http")) rows.set(e.requestId, { path: new URL(e.request.url).pathname, cached: false });
});
cdp.on("Network.requestServedFromCache", (e) => { const row = rows.get(e.requestId); if (row) row.cached = true; });
cdp.on("Network.responseReceivedExtraInfo", (e) => { const row = rows.get(e.requestId); if (row) row.status = e.statusCode; });
await page.goto(url, { waitUntil: "networkidle" });
await browser.close();
for (const r of rows.values()) {
  const how = r.cached ? "from the cache, not asked" : r.status === 304 ? "304, kept its copy" : `${r.status}, downloaded again`;
  console.log(`${r.path.padEnd(30)} ${how}`);
}
```

As APIs da própria página informam uma resposta reconferida como 200, o status da cópia que o navegador
acabou usando; o protocolo das ferramentas de desenvolvedor informa o status que atravessou a rede, que é o
que distingue um 304 de um download. Com o `server.ts` rodando como a aula 8 o deixou:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:3000/courses/git
/courses/git                   200, downloaded again
/fonts/plex-400.woff2          200, downloaded again
/fonts/plex-700.woff2          200, downloaded again
/assets/index-B_kobX3K.js      200, downloaded again
/assets/planner-BNdUlffC.js    200, downloaded again
/covers/git-800.avif           200, downloaded again
```

**Tudo baixado de novo.** O `server.ts` não manda `Cache-Control`, nem `ETag`, nem `Last-Modified`, então o
navegador não tinha nem um tempo de vida nem com que conferir as cópias. Uma segunda visita custa exatamente
o que a primeira custou. O `curl -I` mostra os cabeçalhos de um dos scripts do planner:

```
ana@dev:~/planner$ curl -sI http://localhost:3000/assets/$(ls dist/assets | grep -m1 '^index.*js')
HTTP/1.1 200 OK
content-type: text/javascript
vary: accept-encoding
Date: Sat, 24 Oct 2026 01:03:10 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

Nenhum deles trata de cache. As duas regras da próxima seção corrigem isso.
