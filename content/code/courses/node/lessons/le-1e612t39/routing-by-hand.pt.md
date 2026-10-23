---
title: Roteamento à mão
version: 1
---

**Roteamento é escolher o que fazer a partir do método e do caminho, e com o `node:http` ele é um
`if` que você escreve.** Toda requisição chega a uma função. O método e o caminho juntos nomeiam uma
ação: `GET /links` lista, `POST /links` cria, e o mesmo caminho com um método desconhecido não é uma
página que falta, e sim um método que o recurso não aceita.

```javascript
// routes.js
import http from "node:http";

const routes = {
  "/links": {
    GET: (req, res) => res.end("the list of links\n"),
    POST: (req, res) => res.end("a new link\n"),
  },
  "/health": {
    GET: (req, res) => res.end("ok\n"),
  },
};

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    const route = routes[pathname];
    if (!route) {
      res.statusCode = 404;
      return res.end(`nothing at ${pathname}\n`);
    }
    const handler = route[req.method];
    if (!handler) {
      res.writeHead(405, { allow: Object.keys(route).join(", ") });
      return res.end(`${req.method} is not allowed on ${pathname}\n`);
    }
    handler(req, res);
  })
  .listen(3000, "127.0.0.1");
```

Uma tabela de caminhos, cada um com uma tabela de métodos, é o roteador inteiro. Pergunte quatro
coisas a ele:

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links
the list of links
ana@dev:~/server/native$ curl -s -X POST http://127.0.0.1:3000/links
a new link
ana@dev:~/server/native$ curl -si -X DELETE http://127.0.0.1:3000/links
HTTP/1.1 405 Method Not Allowed
allow: GET, POST
Date: Fri, 16 Oct 2026 23:08:43 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

DELETE is not allowed on /links
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/nothing
nothing at /nothing
ana@dev:~/server/native$ curl -s 'http://127.0.0.1:3000/health?verbose=1'
ok
```

**404 e 405 são respostas diferentes, e a diferença importa para um cliente.** Um 404 diz que o
recurso não existe, então perguntar de novo não adianta. Um 405 diz que ele existe e não faz aquilo, e
o cabeçalho `Allow`, que o HTTP exige num 405, diz o que ele faz. Um roteador que responde 404 para
tudo o que não trata está dizendo a um cliente que `/links` não existe no dia em que o `DELETE` dele
ainda não foi escrito.

O roteamento é pelo `pathname`, não pelo `req.url`, então uma query string não faz uma rota falhar: o
`/health?verbose=1` chegou ao handler do `/health`. Uma barra no fim faz falhar aqui — `/links/` é
outro caminho — e se deveria é uma decisão de cada roteador; o Express a toma na aula 6.
