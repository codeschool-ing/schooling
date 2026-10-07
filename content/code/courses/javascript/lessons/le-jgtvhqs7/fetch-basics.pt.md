---
title: fetch: pedindo a um servidor
version: 2
---

**`fetch(url)` manda uma requisição HTTP e devolve uma promessa de um `Response`.** O corpo da
resposta chega separado, e `response.json()` é uma segunda promessa que o lê e o interpreta como
JSON. As páginas desta aula perguntam ao servidor que o `page` já roda, o `serve.mjs` da aula 1. O
que ele responde em `/api/` vem de mais um arquivo, que ele carrega quando o arquivo está ao lado.
Salve isto em `~/js-tools` como `api.mjs`:

```javascript
// api.mjs: the addresses under /api/ that this lesson fetches from. serve.mjs
// loads it when it sits in the same folder.
//
// Every answer is the same every time, except /api/slow, which really waits,
// and /api/flaky, which fails on purpose until it has been asked enough.
const BOOKS = [
  { id: 1, title: "Dom Casmurro", author: "Machado de Assis", year: 1899 },
  { id: 2, title: "Grande Sertão: Veredas", author: "João Guimarães Rosa", year: 1956 },
  { id: 3, title: "A Hora da Estrela", author: "Clarice Lispector", year: 1977 },
];

function json(res, status, body) {
  const text = JSON.stringify(body);
  res.writeHead(status, { "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(text) });
  res.end(text);
}

export function api(req, res, url, state) {
  const p = url.pathname;
  if (p === "/api/books" && req.method === "GET") return json(res, 200, BOOKS);
  if (p === "/api/books" && req.method === "POST") {
    let body = "";
    req.on("data", (c) => (body += c));
    req.on("end", () => {
      let book;
      try { book = JSON.parse(body); } catch { return json(res, 400, { error: "the body is not JSON" }); }
      if (!book.title) return json(res, 422, { error: "a book needs a title" });
      json(res, 201, { id: 4, ...book });
    });
    return;
  }
  const one = p.match(/^\/api\/books\/(\d+)$/);
  if (one) {
    const b = BOOKS.find((x) => x.id === Number(one[1]));
    return b ? json(res, 200, b) : json(res, 404, { error: `no book ${one[1]}` });
  }
  if (p === "/api/broken") return json(res, 500, { error: "the database is not answering" });
  if (p === "/api/html") {
    res.writeHead(502, { "content-type": "text/html; charset=utf-8" });
    return res.end("<html><body><h1>502 Bad Gateway</h1></body></html>\n");
  }
  if (p === "/api/slow") {
    const ms = Number(url.searchParams.get("ms") || 3000);
    const t = setTimeout(() => json(res, 200, { waited: ms }), ms);
    res.on("close", () => clearTimeout(t));
    return;
  }
  if (p === "/api/flaky") {
    // Fails the first N requests since the server started, then answers.
    state.flaky = (state.flaky || 0) + 1;
    const fails = Number(url.searchParams.get("fails") || 2);
    return state.flaky <= fails
      ? json(res, 503, { error: "busy, try again", attempt: state.flaky })
      : json(res, 200, { ok: true, attempt: state.flaky });
  }
  json(res, 404, { error: "no such endpoint" });
}
```

Seis endereços, cada um feito para mostrar uma coisa. `/api/books` responde com três livros, e
recebe um novo por `POST`. `/api/books/1` a `/api/books/3` respondem com um deles, e qualquer outro
número com um 404. `/api/broken` é um erro do servidor, e `/api/html` a página HTML que um proxy
quebrado manda no lugar do JSON. `/api/slow` demora o quanto mandarem, e `/api/flaky` falha as
primeiras requisições de propósito. As seções abaixo usam um cada. A primeira pede a lista:

```html
<!doctype html>
<ul id="books"></ul>
<script type="module">
  const response = await fetch("/api/books");
  console.log(response.status, response.ok, response.headers.get("content-type"));

  const books = await response.json();
  console.log(Array.isArray(books), books.length);

  document.querySelector("#books").replaceChildren(
    ...books.map((b) => {
      const li = document.createElement("li");
      li.textContent = `${b.title} (${b.year})`;
      return li;
    }),
  );
</script>
```

```
ana@dev:~/js$ page list.html --network --dom '#books'
net  GET /list.html  200  document  495 B
200 true application/json; charset=utf-8
true 3
net  GET /api/books  200  fetch  239 B
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

O `--network` faz o `page` listar toda requisição que a página fez, como o painel de rede do navegador
faria (a aula 22 abre o de verdade). Duas requisições: **a própria página, e o `fetch`, respondido com
`200` e 239 bytes de JSON**.

## Lendo o `Response`

- `response.status` é o código de status HTTP, `200`, e **`response.ok` é `true` para qualquer status
  de 200 a 299**. A aula 6 de `web-fundamentals` cobre o que os códigos significam;
- `response.headers.get("content-type")` é como o servidor rotulou o corpo,
  `application/json; charset=utf-8` aqui. As próximas seções o conferem antes de confiar no corpo;
- **`response.json()` lê o corpo inteiro e o interpreta**, e o resultado foi um array de três livros,
  transformados em itens de lista com `textContent` como a aula 11 fez.

A página usou `<script type="module">` para poder escrever `await` no nível de cima (aula 9). A
requisição foi para `/api/books` na própria origem da página, então nenhuma regra de origem cruzada
se aplicou; pedir a outro servidor a partir de uma página traz o CORS, que a aula 7 de `front-quality`
explica.
