---
title: Uma primeira aplicação Express
version: 1
---

**Uma aplicação Express é uma função que recebe uma requisição e uma resposta, com um roteador e uma
corrente de middlewares dentro.** O `express()` cria uma, o `app.get` acrescenta uma rota, e o
`app.listen` a entrega ao `node:http`, que continua sendo o servidor por baixo. Os experimentos desta
aula ficam numa pasta `demo` dentro do projeto `links`, para que encontrem o Express que a aula 4
instalou:

```javascript
// demo/first.js
import express from "express";

const app = express();

app.get("/", (req, res) => {
  res.send("hello from Express\n");
});

app.get("/links/:code", (req, res) => {
  res.json({ code: req.params.code, asked: req.query });
});

app.listen(3000, "127.0.0.1", () => console.log("listening on http://127.0.0.1:3000"));
```

O `res.json` escreve o JSON e nenhuma quebra de linha depois dele, então num terminal o próximo prompt
começaria na mesma linha da resposta. Uma linha no arquivo de configuração do próprio curl, o
`~/.curlrc`, faz com que ele imprima uma quebra de linha depois de toda resposta daqui em diante:

```
ana@dev:~/server/links$ echo '-w "\n"' >> ~/.curlrc
ana@dev:~/server/links$ cat ~/.curlrc
-w "\n"
```

Inicie o servidor num terminal, e no outro:

```
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: 19
ETag: W/"13-JrSxvmjEhU9ng05ndu7+m0clhpU"
Date: Fri, 16 Oct 2026 23:19:42 GMT
Connection: keep-alive
Keep-Alive: timeout=5

hello from Express

ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links/7ctxqn?visits=1'
{"code":"7ctxqn","asked":{"visits":"1"}}
```

Compare com o `respond.js` da aula 5. **O `res.send` definiu o tipo por você**, `text/html` para uma
string, e o `res.json` definiu `application/json` e escreveu o corpo; os dois contaram o tamanho.
Apareceram dois cabeçalhos novos:

- **`X-Powered-By: Express`** diz a todo cliente qual framework respondeu. Isso não ajuda ninguém a
  não ser quem procura servidores rodando uma versão com uma falha conhecida, e a aula 7 o desliga.
- **`ETag`** é uma impressão digital curta do corpo, que permite a um cliente perguntar "isto
  mudou?" e receber um 304 sem corpo se não tiver mudado. A seção da aula 7 sobre requisições
  condicionais o usa.

O `req.params` e o `req.query` chegaram já lidos. **Os dois continuam sendo o texto do cliente**:
`visits` é a string `"1"`, exatamente como o `searchParams` da aula 5 a dava.

O `app.listen` é um atalho para `http.createServer(app).listen(…)`, e devolve o `http.Server`. Tudo o
que a aula 5 disse sobre o objeto do servidor, o endereço e os timeouts dele, vale para esse objeto.
