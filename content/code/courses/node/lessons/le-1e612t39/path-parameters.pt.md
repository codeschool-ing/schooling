---
title: Parâmetros no caminho
version: 1
---

**`/links/7ctxqn` nomeia um link, e o código nele é um parâmetro.** Uma tabela indexada por caminho
não consegue ter uma entrada por código, então o roteador precisa desmontar o caminho e comparar o
formato dele. Dividi-lo em `/` basta para este serviço:

```javascript
// params.js
import http from "node:http";

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    let parts;
    try {
      parts = pathname.split("/").filter(Boolean).map(decodeURIComponent);
    } catch {
      res.statusCode = 400;
      return res.end("the path is not valid percent-encoding\n");
    }
    if (parts.length === 2 && parts[0] === "links") return res.end(`the link ${JSON.stringify(parts[1])}\n`);
    res.statusCode = 404;
    res.end(`nothing at ${pathname}\n`);
  })
  .listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/7ctxqn
the link "7ctxqn"
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/caf%C3%A9
the link "café"
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/a%2Fb
the link "a/b"
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/%E0%A4%A
the path is not valid percent-encoding
```

**Um caminho chega com codificação percentual**, então um espaço é `%20` e `é` é `%C3%A9`, e o
`decodeURIComponent` o devolve ao normal. Duas consequências:

- **decodifique cada parte depois de dividir, nunca o caminho antes.** Um código com `%2F` decodifica
  para `/`; decodificado antes, ele se dividiria em duas partes e iria para outra rota. A terceira
  requisição mostra ele chegando inteiro, barra incluída.
- **decodificar pode falhar.** `%E0%A4%A` não é UTF-8 válido, e o `decodeURIComponent` lança um
  `URIError`. Sem captura, isso é uma queda numa requisição que qualquer um pode mandar, que é o
  assunto da seção sobre erros nos handlers. Aqui é um 400, um erro do cliente respondido como tal.

Um parâmetro continua sendo o texto do cliente. `"7ctxqn"` é uma string que pode ou não ser um
código, e o serviço a procura em vez de confiar nela; a aula 7 valida parâmetros antes de usá-los.
