---
title: Um erro num handler
version: 1
---

**Uma exceção num handler de requisição que nada captura é uma exceção no processo inteiro.** A aula
1 e a aula 2 mostraram o que isso faz a um programa. Num servidor significa que toda requisição em
andamento, de todo usuário, morre junto com a que lançou o erro.

```javascript
// fragile.js
import http from "node:http";

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    const code = decodeURIComponent(pathname.slice(1)); // throws on bad percent-encoding
    res.end(`you asked for ${code}\n`);
  })
  .listen(3000, "127.0.0.1", () => console.log("listening"));
```

Um caminho malformado, de qualquer pessoa:

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/ok; curl -s http://127.0.0.1:3000/%E0%A4%A; curl -s http://127.0.0.1:3000/ok; echo "curl exit code $?"
you asked for ok
curl exit code 7
```

e no terminal do servidor:

```
ana@dev:~/server/native$ node fragile.js
listening
file:///home/ana/server/native/fragile.js:7
    const code = decodeURIComponent(pathname.slice(1)); // throws on bad percent-encoding
                 ^

URIError: URI malformed
    at decodeURIComponent (<anonymous>)
    at Server.<anonymous> (file:///home/ana/server/native/fragile.js:7:18)
    at Server.emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at HTTPParser.parserOnHeadersComplete (node:_http_common:122:17)

Node.js v22.22.0
```

**A segunda requisição matou o servidor**, e a terceira não encontrou nada escutando: o código de
saída 7 do curl significa que ele não conseguiu se conectar. A URL foi todo o esforço do atacante, e
um serviço que cai com uma entrada assim tem um bug, não azar. O mesmo vale para um handler `async`
cuja promise rejeita: a seção da aula 2 sobre erros que ninguém capturou mostrou que uma rejeição sem
handler também encerra o processo.

## Capturando na borda

A solução é um `try` em volta do handler inteiro, para que todo erro vire uma resposta:

```javascript
// sturdy.js
import http from "node:http";

http
  .createServer(async (req, res) => {
    try {
      const { pathname } = new URL(req.url, "http://localhost");
      const code = decodeURIComponent(pathname.slice(1));
      res.end(`you asked for ${code}\n`);
    } catch (err) {
      console.error(`${req.method} ${req.url}: ${err.message}`);
      res.statusCode = err instanceof URIError ? 400 : 500;
      res.end(res.statusCode === 400 ? "bad request\n" : "internal error\n");
    }
  })
  .listen(3000, "127.0.0.1", () => console.log("listening"));
```

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/ok; curl -s http://127.0.0.1:3000/%E0%A4%A; curl -s http://127.0.0.1:3000/ok
you asked for ok
bad request
you asked for ok
```

Duas regras estão nesse `catch`. **Os detalhes vão para o log, e o cliente recebe uma frase curta e
fixa**: um stack trace numa resposta conta a um estranho de quais arquivos e bibliotecas o servidor é
feito. E **o status diz de quem foi a culpa**: um 400 para uma requisição que nunca poderia dar certo,
um 500 para uma falha nossa, que é a que deve acordar alguém. A aula 6 mostra a mesma regra no
Express, onde uma função de tratamento de erros faz isso para todas as rotas.
