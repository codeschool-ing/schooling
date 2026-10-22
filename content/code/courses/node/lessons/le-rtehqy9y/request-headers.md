---
title: Reading request headers
version: 1
---

**`req.get(name)` reads a header by any capitalisation, and three helpers answer the questions headers
are usually read for.** They save writing the parsing by hand, and they get the details right:

| helper | the question | reads |
|---|---|---|
| `req.get("x-admin-key")` | what does this header say? | any header |
| `req.is("application/json")` | is the body of this type? | `content-type` |
| `req.accepts(["json", "text"])` | which of these can the client take? | `accept` |
| `req.ip`, `req.ips` | who sent it? | the socket, and `x-forwarded-for` when trusted |

`req.ip` has the last section of this lesson to itself. The other three in a demo:

```javascript
// demo/headers.js
import express from "express";

const app = express();
app.use(express.text());

app.post("/echo", (req, res) => {
  res.json({ isJson: req.is("application/json"), isText: req.is("text/*"), agent: req.get("user-agent") });
});

app.get("/links/:code", (req, res) => {
  const link = { code: req.params.code, url: "https://example.com/" };
  const kind = req.accepts(["json", "text"]);
  if (kind === "text") return res.type("text").send(`${link.code} -> ${link.url}\n`);
  if (kind === "json") return res.json(link);
  res.status(406).json({ error: "this answers in JSON or plain text" });
});

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s -H 'content-type: text/plain' -d 'hello' http://127.0.0.1:3000/echo
{"isJson":false,"isText":"text/plain","agent":"curl/8.5.0"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{}' http://127.0.0.1:3000/echo
{"isJson":"application/json","isText":false,"agent":"curl/8.5.0"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
{"code":"7ctxqn","url":"https://example.com/"}
ana@dev:~/server/links$ curl -s -H 'accept: text/plain' http://127.0.0.1:3000/links/7ctxqn
7ctxqn -> https://example.com/

ana@dev:~/server/links$ curl -s -H 'accept: image/png' http://127.0.0.1:3000/links/7ctxqn
{"error":"this answers in JSON or plain text"}
```

**`req.is` answers with the type that matched, or `false`**, and it understands wildcards and
parameters, `text/plain; charset=utf-8` included, which a string comparison on the header would get
wrong. **`req.accepts` is content negotiation**: the client says what it can take, in order of
preference, and the server picks the best it has. curl's default `Accept: */*` takes anything, so the
first offered won, JSON. A client that can take neither gets a 406, Not Acceptable, which is a clearer
answer than a body it cannot read.

Negotiation is rare in an API that answers JSON to everybody, and common at its edges: an endpoint
that sends a CSV to a spreadsheet and JSON to a program, or an error page that is HTML to a browser and
JSON to `fetch`.
