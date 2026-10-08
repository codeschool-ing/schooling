---
title: fetch: asking a server
version: 2
---

**`fetch(url)` sends an HTTP request and returns a promise of a `Response`.** The response's body
arrives separately, and `response.json()` is a second promise that reads it and parses it as JSON.
The pages in this lesson ask the server `page` already runs, `serve.mjs` from lesson 1. What it
answers under `/api/` comes from one more file, which it loads when the file sits beside it. Save
this in `~/js-tools` as `api.mjs`:

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

Six addresses, each made to show one thing. `/api/books` answers with three books, and takes a new
one by `POST`. `/api/books/1` to `/api/books/3` answer with one of them, and any other number with a
404. `/api/broken` is a server error, and `/api/html` the HTML page a broken proxy sends instead of
JSON. `/api/slow` takes as long as it is told to, and `/api/flaky` fails its first requests on
purpose. The sections below use one each. The first asks for the list:

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

`--network` makes `page` list every request the page made, as the browser's network panel would
(lesson 22 opens the real one). Two requests: **the page itself, and the `fetch`, answered `200` with
239 bytes of JSON**.

## Reading the `Response`

- `response.status` is the HTTP status code, `200`, and **`response.ok` is `true` for any status from
  200 to 299**. `web-fundamentals` lesson 6 covers what the codes mean;
- `response.headers.get("content-type")` is how the server labelled the body,
  `application/json; charset=utf-8` here. The next sections check it before trusting the body;
- **`response.json()` reads the whole body and parses it**, and the result was an array of three
  books, turned into list items with `textContent` as lesson 11 did.

The page used `<script type="module">` so it could write `await` at the top level (lesson 9). The
request went to `/api/books` on the page's own origin, so no cross-origin rules applied; asking a
different server from a page brings in CORS, which `front-quality` lesson 7 explains.
