---
title: Quando nenhuma rota casa
version: 1
---

**Quando nenhuma rota casa, a requisição cai do fim da corrente, e o Express responde 404 com
`Cannot GET /caminho` em HTML.** Para responder no formato do próprio serviço, acrescente um middleware
depois de todas as rotas, com os três parâmetros comuns: qualquer coisa que chegue a ele não casou com
nada.

```javascript
// demo/notfound.js
import express from "express";

const app = express();

const links = express.Router();
links.get("/", (req, res) => res.json([]));
links.post("/", (req, res) => res.status(201).json({ code: "7ctxqn" }));
links.all("/", (req, res) => res.set("allow", "GET, POST").status(405).json({ error: "method not allowed" }));
app.use("/links", links);

app.use((req, res) => res.status(404).json({ error: `nothing at ${req.path}` }));

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/nothing
{"error":"nothing at /nothing"}
ana@dev:~/server/links$ curl -si -X DELETE http://127.0.0.1:3000/links | grep -iE "^HTTP|^allow|error"
HTTP/1.1 405 Method Not Allowed
allow: GET, POST
{"error":"method not allowed"}
```

**O 405 voltou**, escrito do jeito que o Express permite: o `all` casa com todo método, e posto depois
dos de verdade ele pega só os métodos que eles não pegaram. O cabeçalho `Allow` é escrito à mão, e
precisa acompanhar as rotas acima dele, que é o custo de o Express não saber dos métodos que nunca lhe
contaram.

O handler de 404 vem depois de tudo, e **antes do handler de erros**: um 404 não é um erro, só uma
resposta. Na corrente da seção sobre middleware, o serviço links termina com esses dois, nessa ordem.
