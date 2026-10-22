---
title: The query string
version: 1
---

**`req.query` is the query string, parsed into an object of strings.** How it is parsed is a setting,
and Express 5 changed the default to the simple one. Asking a demo server to echo it back shows what
that means:

```javascript
// demo/query.js
import express from "express";

const app = express();
app.get("/q", (req, res) => res.json(req.query));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -sg 'http://127.0.0.1:3000/q?limit=10&tag=a&tag=b&empty=&user[admin]=true'
{"limit":"10","tag":["a","b"],"empty":"","user[admin]":"true"}
```

`-g` stops curl from treating the square brackets as its own pattern syntax and sends them as they
are.

- **Every value is a string**, or an array of strings: `limit` is `"10"`, and `empty` is `""`.
- **A name given twice becomes an array**: `tag` is `["a", "b"]`. A route that expects a string has
  to be ready for an array, because the client decides.
- **Brackets mean nothing**: `user[admin]` is a key of its own, not an object `user` with a property
  `admin`. Express 4 parsed it into an object, with the `qs` package of lesson 4's audit, and nested
  objects built from a stranger's query string are where prototype pollution advisories come from. The
  simple parser cannot build one.

## A limit, checked

The admin's list of links grows without bound, so it takes a `limit`, and a limit from a query string
has to be turned into a number and kept in range:

```javascript
// demo/limit.js
import express from "express";

function limitFrom(query, fallback = 20, most = 100) {
  if (query.limit === undefined) return fallback;
  const n = Number(query.limit);
  if (!Number.isInteger(n) || n < 1 || n > most) return null;
  return n;
}

const app = express();
app.get("/links", (req, res) => {
  const limit = limitFrom(req.query);
  if (limit === null) return res.status(400).json({ error: "limit must be a whole number from 1 to 100" });
  res.json({ limit });
});
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links'
{"limit":20}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=5'
{"limit":5}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=2.5'
{"error":"limit must be a whole number from 1 to 100"}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=abc'
{"error":"limit must be a whole number from 1 to 100"}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=1&limit=2'
{"error":"limit must be a whole number from 1 to 100"}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=10000000'
{"error":"limit must be a whole number from 1 to 100"}
```

`Number("abc")` is `NaN`, `Number("2.5")` is not an integer, and `Number(["1", "2"])` is `NaN` too, so
one `Number.isInteger` refuses all three. **A maximum is part of the check**, not a nicety: without
one, `limit=10000000` is a request to read the whole store and send it, which is lesson 2's blocked
loop asked for politely.
