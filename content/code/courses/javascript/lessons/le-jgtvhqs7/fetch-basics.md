---
title: fetch: asking a server
version: 1
---

**`fetch(url)` sends an HTTP request and returns a promise of a `Response`.** The response's body
arrives separately, and `response.json()` is a second promise that reads it and parses it as JSON.
The lab's server answers `/api/books` with three books:

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
