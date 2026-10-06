---
title: A 404 is not a failure, to fetch
version: 1
---

The most important fact about `fetch` is what it does **not** treat as an error:

```html
<!doctype html>
<script type="module">
  for (const path of ["/api/books/2", "/api/books/9", "/api/broken"]) {
    try {
      const response = await fetch(path);
      const body = await response.json();
      console.log(path, "resolved:", response.status, response.ok, JSON.stringify(body));
    } catch (err) {
      console.log(path, "rejected:", err.name);
    }
  }
</script>
```

```
ana@dev:~/js$ page status.html
/api/books/2 resolved: 200 true {"id":2,"title":"Grande Sertão: Veredas","author":"João Guimarães Rosa","year":1956}
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
/api/books/9 resolved: 404 false {"error":"no book 9"}
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
/api/broken resolved: 500 false {"error":"the database is not answering"}
```

Three requests: a book that exists, a book that does not, and an endpoint whose database is down.
**All three promises resolved.** The 404 and the 500 came back as ordinary responses with
`ok: false`, and the `catch` never ran. The `[error]` lines are the browser's own console noting the
failed status codes; they are not exceptions your code can catch.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"What a call to fetch can end in. If no response arrives at all, because the connection was refused, the network is down or the request was aborted, the promise rejects. If any response arrives, whatever its status, the promise resolves. Code then checks the content type before reading JSON, and response.ok before trusting the body.\"><defs><marker id=\"fetch-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"fetch-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"fetch-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fetch(url)</text><rect x=\"200\" y=\"20\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">no response</text><text x=\"315.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refused, offline, aborted</text><rect x=\"200\" y=\"168\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a response, any status</text><text x=\"315.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200, 404, 500, 502</text><path d=\"M140 112 L196 52\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-amber)\"></path><path d=\"M140 132 L196 192\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-phosphor)\"></path><rect x=\"490\" y=\"20\" width=\"210\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the promise rejects</text><text x=\"595.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">TypeError / AbortError</text><path d=\"M430 48 L486 48\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-amber)\"></path><rect x=\"490\" y=\"120\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. content type JSON?</text><rect x=\"490\" y=\"180\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2. response.ok?</text><path d=\"M430 186 L486 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-phosphor)\"></path><path d=\"M595 160 L595 176\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fetch-ah-paper-dim)\"></path></svg>", "caption": "fetch rejects only when no response arrives; every status, 404 and 500 included, is a resolved promise for your code to check."}
```

**`fetch` rejects only when no response arrives at all.** A response with any status is a successful
round trip as far as `fetch` is concerned, because the server did answer. Whether the answer is good
news is the program's question, and if the program never asks, a page renders "undefined" where a
title should be, or an error message as though it were a book.

## One function that checks

```javascript
export async function getJSON(url, options) {
  const response = await fetch(url, options);
  const type = response.headers.get("content-type") ?? "";
  if (!type.includes("application/json")) {
    throw new Error(`${url}: expected JSON, got ${response.status} ${type || "no type"}`);
  }
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`${url}: ${response.status} ${body.error ?? ""}`.trim());
  }
  return body;
}
```

The rest of this lesson uses this helper. It turns everything that is not a usable JSON answer into an
error, so the caller has one `try`/`catch` and no silent failures:

1. **the content type must be JSON**, or `response.json()` would throw a confusing `SyntaxError` on
   whatever came instead;
2. the body is read, because a good API explains its errors in it, as this one did with
   `"no book 9"`;
3. **`response.ok` must be true**, or it throws with the status and the server's explanation.
