---
title: Erros, e o middleware que os trata
version: 1
---

**No Express 5, um erro lançado numa rota, ou uma promise devolvida por uma rota que rejeita, vai
para os handlers de erro em vez de encerrar o processo.** Essa mudança é o principal motivo para estar
na versão 5: no Express 4 uma promise rejeitada numa rota `async` era a rejeição não tratada da aula
2, e o servidor morria exatamente como o `fragile.js` da aula 5.

```javascript
// demo/errors.js
import express from "express";

const app = express();

app.get("/sync", () => {
  throw new Error("thrown in a route");
});
app.get("/async", async () => {
  await new Promise((resolve) => setTimeout(resolve, 10));
  throw new Error("rejected in an async route");
});
app.get("/next", (req, res, next) => {
  next(new Error("passed to next"));
});

app.listen(3000, "127.0.0.1", () => console.log("listening"));
```

```
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/sync
500
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/async
500
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/next
500
```

Os três viraram um 500 e o servidor continuou de pé. O terceiro jeito, o **`next(err)`**, é como um
callback que não é promise relata um erro, e como um middleware desiste de uma requisição que não
consegue tratar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O caminho de um pedido pela cadeia do Express. Normalmente ele passa pelo log, pelo leitor de JSON e pelo roteador, e uma rota responde. Quando uma rota lança um erro, ou a promise dela rejeita, o Express pula todo middleware comum que ainda falta e vai direto ao handler de erro, o de quatro parâmetros, que responde com um status e um corpo JSON.\"><rect x=\"20\" y=\"60\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">log</text><rect x=\"130\" y=\"60\" width=\"116\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"188.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">express.json</text><rect x=\"260\" y=\"60\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"308.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roteador</text><rect x=\"370\" y=\"60\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rota</text><rect x=\"480\" y=\"60\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"513.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">(err, req, res, next)</text><line x1=\"116\" y1=\"82\" x2=\"128\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"128.0,82.0 120.6,85.1 120.6,78.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"246\" y1=\"82\" x2=\"258\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,82.0 250.6,85.1 250.6,78.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"356\" y1=\"82\" x2=\"368\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,82.0 360.6,85.1 360.6,78.9\" fill=\"var(--phosphor)\"></polygon><text x=\"418\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">responde: 200, 201…</text><path d=\"M418 104 C 418 170, 630 170, 630 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"630\" y1=\"116\" x2=\"630\" y2=\"106\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,106.0 633.1,113.4 626.9,113.4\" fill=\"var(--amber)\"></polygon><text x=\"520\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lança, ou rejeita: tudo no meio é pulado</text><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um pedido, da esquerda para a direita</text></svg>", "caption": "Um erro não percorre a cadeia: ele pula para o único middleware que recebe quatro argumentos.", "same": ["log"]}
```

## O handler padrão fala demais

Sem handler próprio, o padrão do Express escreve o erro na resposta. O que ele escreve depende do
`NODE_ENV`:

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/sync | head -8
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>Error: thrown in a route<br> &nbsp; &nbsp;at file:///home/ana/server/links/demo/errors.js:7:9<br> &nbsp; &nbsp;at Layer.handleRequest (/home/ana/server/links/node_modules/router/lib/layer.js:152:17)<br> &nbsp; &nbsp;at next (/home/ana/server/links/node_modules/router/lib/route.js:157:13)<br> &nbsp; &nbsp;at Route.dispatch (/home/ana/server/links/node_modules/router/lib/route.js:117:3)<br> &nbsp; &nbsp;at handle (/home/ana/server/links/node_modules/router/index.js:435:11)<br> &nbsp; &nbsp;at Layer.handleRequest (/home/ana/server/links/node_modules/router/lib/layer.js:152:17)<br> &nbsp; &nbsp;at /home/ana/server/links/node_modules/router/index.js:295:15<br> &nbsp; &nbsp;at processParams (/home/ana/server/links/node_modules/router/index.js:582:12)<br> &nbsp; &nbsp;at next (/home/ana/server/links/node_modules/router/index.js:291:5)<br> &nbsp; &nbsp;at Function.handle (/home/ana/server/links/node_modules/router/index.js:186:3)</pre>
```

Pare o servidor, inicie de novo como `NODE_ENV=production node demo/errors.js`, e pergunte a mesma
coisa:

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/sync
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>Internal Server Error</pre>
</body>
</html>
```

**A não ser que o `NODE_ENV` seja `production`, a resposta leva o stack trace**: caminhos de arquivo
no servidor, os nomes das bibliotecas, números de linha. Essa é a regra da aula 5 quebrada por
padrão, e é por isso que a variável importa, assunto a que a aula 9 volta. Em produção ela disse só
`Internal Server Error`. De qualquer jeito é HTML, que um cliente JSON não quer.

## Escrevendo o seu

Um handler de erros é um middleware com **quatro** parâmetros, `(err, req, res, next)`, acrescentado
depois de todas as rotas. O Express o reconhece por essa contagem:

```javascript
// demo/handler.js
import express from "express";

const app = express();
app.use(express.json({ limit: "1kb" }));

app.post("/links", (req, res) => res.status(201).json({ received: req.body }));
app.get("/broken", () => {
  throw new Error("database password rejected");
});

app.use((err, req, res, next) => {
  const status = err.status ?? 500;
  if (status >= 500) console.error(`${req.method} ${req.originalUrl}:`, err);
  res.status(status).json({ error: status >= 500 ? "internal error" : err.message });
});

app.listen(3000, "127.0.0.1", () => console.log("listening"));
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/broken
{"error":"internal error"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": ' http://127.0.0.1:3000/links
{"error":"Unexpected end of JSON input"}
ana@dev:~/server/links$ head -c 2000 /dev/zero | tr '\0' 'a' | curl -s -H 'content-type: application/json' -d @- http://127.0.0.1:3000/links
{"error":"request entity too large"}
```

**Os erros que o `express.json` lançou trazem um `status`**, 400 para JSON ruim e 413 para grande
demais, então o handler repassa a mensagem deles; um erro sem status é nosso, um 500, e a mensagem
dele fica no log, onde `database password rejected` deve ficar. Essa é a borda da aula 5 em seis
linhas, e ela vale para toda rota que a aplicação vier a ter.
