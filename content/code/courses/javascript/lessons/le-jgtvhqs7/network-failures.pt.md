---
title: Quando nenhuma resposta vem
version: 2
---

Com o `getJSON` no lugar, todo jeito de uma requisição dar errado termina no mesmo `catch`, com uma
mensagem que diz qual foi:

```html
<!doctype html>
<script type="module">
  import { getJSON } from "./get-json.js";

  for (const url of ["/api/books/2", "/api/books/9", "/api/html", "http://127.0.0.1:8099/api/books"]) {
    try {
      const book = await getJSON(url);
      console.log("ok:", book.title);
    } catch (err) {
      console.log(`${err.name}: ${err.message}`);
    }
  }
</script>
```

```
ana@dev:~/js$ page failures.html
ok: Grande Sertão: Veredas
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
Error: /api/books/9: 404 no book 9
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
Error: /api/html: expected JSON, got 502 text/html; charset=utf-8
[error] Failed to load resource: net::ERR_CONNECTION_REFUSED
TypeError: Failed to fetch
```

| requisição | o que aconteceu | o que a página recebeu |
|---|---|---|
| `/api/books/2` | uma resposta boa | o livro |
| `/api/books/9` | uma resposta, status 404 | um `Error` dizendo o status e o motivo do servidor |
| `/api/html` | uma resposta, uma página HTML de erro de um proxy | um `Error` dizendo que esperava JSON |
| porta 8099 | **nenhuma resposta**: nada escuta ali | **`TypeError: Failed to fetch`** |

A terceira linha é comum em implantações de verdade: um gateway ou proxy na frente da API falha e
responde com a sua própria página HTML. **Sem a conferência do tipo de conteúdo, `response.json()`
teria lançado um `SyntaxError` sobre um `<` inesperado**, o que manda as pessoas olharem o próprio
código de leitura.

A quarta linha é a única em que o próprio `fetch` rejeitou. A mensagem do navegador é vaga de
propósito, `Failed to fetch`, seja a causa uma conexão recusada, falta de rede, ou uma requisição que
o navegador recusou por segurança; a linha do console acima dela, `ERR_CONNECTION_REFUSED`, é escrita
para quem desenvolve e não fica disponível para o script.

## O mesmo no Node

Um programa rodado com `node` não tem um `page` para subir o servidor por ele, então suba você
mesmo, num segundo terminal e de dentro de `~/js`:

```sh
node ~/js-tools/serve.mjs
```

Ele diz `serving` e a pasta e o endereço que serve, e fica rodando até você apertar Ctrl+C. De volta
ao primeiro terminal:

```javascript
for (const url of ["http://127.0.0.1:8080/api/books/2", "http://127.0.0.1:8099/api/books"]) {
  try {
    const response = await fetch(url);
    console.log("status", response.status);
  } catch (err) {
    console.log(`${err.name}: ${err.message}; cause: ${err.cause?.code}`);
  }
}
```

```
ana@dev:~/js$ node failures-node.mjs
status 200
TypeError: fetch failed; cause: ECONNREFUSED
```

O `fetch` do Node segue as mesmas regras, com **outra mensagem e um `cause`** que diz o que aconteceu
por baixo: `ECONNREFUSED`, a conexão recusada. Um programa de servidor pode registrar isso, o que é
bem mais útil que "fetch failed" num log às três da manhã.
