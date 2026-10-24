---
title: Duas regras
version: 1
---

**Todo arquivo que o planner manda cai numa de duas regras**, e qual depende do nome dele.

- **Um arquivo cujo nome leva um hash do conteúdo**, `index-B_kobX3K.js`, nunca muda naquele endereço: um
  conteúdo diferente ganha um nome diferente, então o HTML do próximo build aponta para outro lugar. Ele pode
  ser guardado por um ano sem perguntar: `public, max-age=31536000, immutable`.
- **Todo o resto** pode mudar no mesmo endereço: as páginas, o plano, o aviso, as imagens e as fontes, que
  estão em `public/` com nomes que não mudam. É guardado e conferido toda vez: `no-cache`, com um `ETag` para
  conferir.

O Vite escreve o primeiro tipo em `dist/assets/` e nada mais escreve ali, então a regra é um teste do caminho.

## No server.ts

O `send` ganha um quinto argumento, o `Cache-Control` a mandar, e um ETag próprio, um SHA-1 do corpo, que ele
compara com o `If-None-Match` do navegador antes de mandar qualquer coisa. Primeiro o import, depois do de
`node:zlib`:

```typescript
import { createHash } from "node:crypto";
```

Depois troque o `send`, com o comentário, por este, que também define a regra:

```typescript
// Every answer goes through here. Text shrinks with gzip when the browser can read it;
// cache says how long it may be kept; and the ETag, a hash of the body, lets a browser
// that has a copy ask "is it still this?" and be told 304 instead of sent it again.
const send = (req: IncomingMessage, res: ServerResponse, type: string, body: string | Buffer, cache: string) => {
  const etag = `"${createHash("sha1").update(body).digest("base64url")}"`;
  const head = { "content-type": type, vary: "accept-encoding", "cache-control": cache, etag };
  if (req.headers["if-none-match"] === etag) {
    res.writeHead(304, head).end();
    return;
  }
  const gzip = /\bgzip\b/.test(req.headers["accept-encoding"] ?? "");
  res.writeHead(200, { ...head, ...(gzip && { "content-encoding": "gzip" }) });
  res.end(gzip ? gzipSync(body) : body);
};
// A file whose name carries a hash of its contents never changes, so it may be kept a year
// without asking; anything else is kept and checked again every time.
const cacheFor = (pathname: string) =>
  pathname.startsWith("/assets/") ? "public, max-age=31536000, immutable" : "no-cache";
```

O ETag é o hash do corpo antes da compressão, então a mesma página tem o mesmo ETag mandada com gzip ou sem.
Um 304 não leva corpo nem `content-encoding`, só os cabeçalhos da cópia que o navegador já tem. E as duas
chamadas passam uma regra. No ramo dos arquivos:

```typescript
      send(req, res, types[extname(pathname)] ?? "application/octet-stream", body, cacheFor(pathname));
```

e no ramo das páginas:

```typescript
  send(req, res, "text/html; charset=utf-8", html, "no-cache");
```

Reinicie o `server.ts` e volte:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:3000/courses/git
/courses/git                   200, downloaded again
/fonts/plex-400.woff2          200, downloaded again
/fonts/plex-700.woff2          200, downloaded again
/assets/index-B_kobX3K.js      200, downloaded again
/assets/planner-BNdUlffC.js    200, downloaded again
/covers/git-800.avif           200, downloaded again
```

**Os dois scripts vieram do cache sem requisição, e todo o resto foi um 304.** A página, as fontes e a capa
foram perguntadas e mantidas; nada foi baixado duas vezes. Um deploy ainda chega a todo visitante na hora: o
HTML novo é um ETag novo, então ele é baixado, e cita os scripts novos pelos nomes novos.
