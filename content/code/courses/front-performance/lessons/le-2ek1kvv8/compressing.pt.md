---
title: Comprimindo o que o servidor manda
version: 1
---

**Um navegador diz em toda requisição que compressões consegue ler**, no cabeçalho `accept-encoding`, e
um servidor que pode usar uma comprime o corpo e diz isso em `content-encoding`. Todo navegador em uso
lê `gzip`; a maioria também lê `br`, o Brotli, que comprime texto um pouco melhor. O Node tem os dois
em `node:zlib`. Esta seção usa `gzip`, porque é o que todo cliente lê.

Três mudanças no `server.ts`. Primeiro os imports: troque a primeira linha por estas duas, que
acrescentam os tipos de uma requisição e de uma resposta, e o compressor:

```typescript
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { gzipSync } from "node:zlib";
```

Depois uma função por onde toda resposta passa. Acrescente-a logo depois da linha que define o `esc`:

```typescript
// Every answer goes through here. Text shrinks to a fraction of its size with gzip, and a
// browser says in accept-encoding whether it can read it; vary tells a cache the answer
// depends on that header.
const send = (req: IncomingMessage, res: ServerResponse, type: string, body: string | Buffer) => {
  const gzip = /\bgzip\b/.test(req.headers["accept-encoding"] ?? "");
  res.writeHead(200, { "content-type": type, vary: "accept-encoding", ...(gzip && { "content-encoding": "gzip" }) });
  res.end(gzip ? gzipSync(body) : body);
};
```

O `vary` importa para as aulas de cache: um cache que guardasse uma resposta só para todo mundo
entregaria uma página comprimida a um cliente que não consegue lê-la. A aula 9 trata desse cabeçalho.

Por fim, os dois lugares que respondem com corpo passam a usá-la. No ramo dos arquivos, troque as duas
linhas que escrevem o cabeçalho e o corpo por:

```typescript
      send(req, res, types[extname(pathname)] ?? "application/octet-stream", body);
```

e no fim do ramo das páginas, troque as mesmas duas linhas por:

```typescript
  send(req, res, "text/html; charset=utf-8", html);
```

Reinicie o `server.ts` e peça a página inicial como um navegador pede:

```
ana@dev:~/planner$ curl -s -H 'accept-encoding: gzip' -o /dev/null -D - http://localhost:3000/ | sed '/^\r$/q'
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
vary: accept-encoding
content-encoding: gzip
Date: Sat, 24 Oct 2026 00:15:14 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked
```

`content-encoding: gzip`: o corpo que vem depois está comprimido, e o navegador o desfaz antes de ler.
Meça de novo, com o método padrão:

```
ana@dev:~/planner$ node gen.ts 5000 && npm run lighthouse -- http://localhost:3000/ >/dev/null && node tools/report.ts report.report.json
5000 courses
performance 75, throttling simulate
  FCP  4.3 s    weight 10
  LCP  4.3 s    weight 25
  TBT  10 ms    weight 30
  CLS  0        weight 25
  SI   4.3 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 18 KiB
  insight: Document request latency, Est savings of 414 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 300 ms
  request /                            done at    39 ms, 633040 B
  request /assets/index-C9VFYfGa.js    done at    63 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at    63 ms, 538 B
  request /favicon.svg                 done at   102 ms, 9695 B
```

**Cem, e o LCP foi de 4,3 segundos para 1,3.** O HTML foi de mais de seiscentos kilobytes para uns
cinquenta, e o script e a folha de estilo também ficaram menores. Nada na página mudou; os mesmos bytes
viajam numa caixa menor.

## Onde a compressão costuma morar

**Em produção, um servidor como o `server.ts` raramente comprime sozinho.** O proxy reverso na frente
dele, nginx ou Caddy, ou a CDN da aula 9, faz isso para toda aplicação atrás, e em geral com Brotli
também. Fazer na aplicação é certo aqui, porque não há nada na frente dela; num deploy de verdade,
confira o cabeçalho de uma resposta real antes de acrescentar, já que comprimir duas vezes desperdiça
tempo e não comprimir em lugar nenhum é um dos achados mais comuns do Lighthouse.

O `gzipSync` comprime cada resposta de novo, toda vez. Para uma página desenhada por requisição esse é
o preço; para um arquivo que nunca muda, como o script do build, um servidor pode comprimi-lo uma vez, no
build, e mandar a cópia guardada.
