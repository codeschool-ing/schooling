---
title: A requisição, do jeito que o Node a entrega
version: 1
---

**O objeto da requisição traz a linha da requisição e os cabeçalhos, já lidos, e o corpo como um
stream.** Um servidor que só conta o que recebeu mostra tudo isso:

```javascript
// echo.js: say what arrived.
import http from "node:http";

http
  .createServer((req, res) => {
    const url = new URL(req.url, "http://localhost");
    res.setHeader("content-type", "text/plain; charset=utf-8");
    res.end(
      [
        `method:  ${req.method}`,
        `url:     ${req.url}`,
        `path:    ${url.pathname}`,
        `query:   ${JSON.stringify(Object.fromEntries(url.searchParams))}`,
        `version: HTTP/${req.httpVersion}`,
        `headers: ${JSON.stringify(req.headers)}`,
        `raw:     ${JSON.stringify(req.rawHeaders)}`,
        "",
      ].join("\n"),
    );
  })
  .listen(3000, "127.0.0.1");
```

Com ele rodando num terminal, pergunte algo a partir do outro, com um cabeçalho seu em letras
misturadas:

```
ana@dev:~/server/native$ curl -s -H 'X-Request-Id: abc-123' 'http://127.0.0.1:3000/links/7ctxqn?visits=1&format=json'
method:  GET
url:     /links/7ctxqn?visits=1&format=json
path:    /links/7ctxqn
query:   {"visits":"1","format":"json"}
version: HTTP/1.1
headers: {"host":"127.0.0.1:3000","user-agent":"curl/8.5.0","accept":"*/*","x-request-id":"abc-123"}
raw:     ["Host","127.0.0.1:3000","User-Agent","curl/8.5.0","Accept","*/*","X-Request-Id","abc-123"]
```

Leia linha a linha, porque cada uma é uma regra:

- **O `req.url` não é uma URL.** É o caminho e a query exatamente como o cliente mandou, sem host. O
  `new URL(req.url, "http://localhost")` lhe dá uma base para que o parser de URL consiga dividi-lo; a
  base nunca é usada para mais nada.
- **A query string é o texto do cliente.** O `searchParams` a decodifica em nomes e valores, e todo
  valor é string: `visits` é `"1"`, não `1`.
- **O `req.headers` tem todo nome em minúsculas**, como quer que o cliente tenha escrito:
  `X-Request-Id` chegou como `x-request-id`. Nomes de cabeçalho HTTP não diferenciam maiúsculas, então
  o Node os normaliza uma vez, e `req.headers["content-type"]` é a única grafia que funciona. O
  `req.rawHeaders` guarda o texto original, em pares, para o raro programa que precisa dele.
- **O `host` também veio do cliente.** Ele diz qual nome o cliente usou para chegar até você, e um
  cliente pode pôr qualquer coisa ali; nunca o use para decidir quem é alguém.

O `curl -v` imprime a requisição que mandou, que é a outra metade da mesma imagem: as linhas que
começam com `>` são o que chegou ao servidor.

```
ana@dev:~/server/native$ curl -sv http://127.0.0.1:3000/ 2>&1 | grep '^>'
> GET / HTTP/1.1
> Host: 127.0.0.1:3000
> User-Agent: curl/8.5.0
> Accept: */*
> 
```
