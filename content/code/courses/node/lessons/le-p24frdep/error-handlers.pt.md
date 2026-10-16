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
