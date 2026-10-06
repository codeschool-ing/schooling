---
title: When no answer comes
version: 1
---

With `getJSON` in place, every way a request can go wrong ends up in the same `catch`, with a message
that says which way it was:

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

| request | what happened | what the page got |
|---|---|---|
| `/api/books/2` | a good answer | the book |
| `/api/books/9` | an answer, status 404 | an `Error` naming the status and the server's reason |
| `/api/html` | an answer, an HTML error page from a proxy | an `Error` saying it expected JSON |
| port 8099 | **no answer**: nothing listens there | **`TypeError: Failed to fetch`** |

The third row is common in real deployments: a gateway or a proxy in front of the API fails and
answers with its own HTML page. **Without the content-type check, `response.json()` would have thrown
a `SyntaxError` about an unexpected `<`**, which sends people looking at their own parsing code.

The fourth row is the only one where `fetch` itself rejected. The browser's message is deliberately
vague, `Failed to fetch`, whether the cause was a refused connection, no network, or a request the
browser refused for security reasons; the console line above it, `ERR_CONNECTION_REFUSED`, is
written for the developer and is not available to the script.

## The same in Node

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

Node's `fetch` follows the same rules, with **a different message and a `cause`** that says what
happened underneath: `ECONNREFUSED`, the connection refused. A server program can log that, which is
far more useful than "fetch failed" in a log at three in the morning.
