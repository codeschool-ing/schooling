---
title: Validating what a client sends
version: 1
---

**Everything in a request came from somebody you do not control, and a route checks it before it
uses it.** Lesson 5 checked one thing about a new link, that its `url` was a web address. A request
can be wrong in more ways than that, and the reply is more useful when it says every way at once.

Three rules shape the check that follows:

- **an allowlist, not a blocklist.** The body may hold `url` and nothing else. A field the service
  does not know is refused, rather than ignored, so that a client who misspells `ur1` finds out at
  once instead of wondering why the link has no URL;
- **types before values.** `typeof url !== "string"` comes first, because every other test on a
  number or an object would give nonsense;
- **a limit on everything with a length.** A URL of two megabytes is not an address anybody needs,
  and 2048 characters is a common choice for the limit, long enough for any address a person would
  shorten.

The routes, with this check, with lesson 7's parameter check and with the limit on the list:

```schooling-example
{"language": "javascript", "file": "src/links.js", "parts": [
 {"code": "// src/links.js: the routes under /links.\nimport express from \"express\";\nimport { requireKey } from \"./admin.js\";\nimport { isCode } from \"./code.js\";\nimport * as store from \"./store.js\";\n\nexport const links = express.Router();\n\nfunction isWebAddress(text) {\n  try {\n    const url = new URL(text);\n    return url.protocol === \"http:\" || url.protocol === \"https:\";\n  } catch {\n    return false;\n  }\n}", "note": "The routes import `isCode` now, for the parameter check."},
 {"code": "function problemsWith(body) {\n  if (typeof body !== \"object\" || body === null || Array.isArray(body)) return [\"send a JSON object\"];\n  const problems = [];\n  for (const key of Object.keys(body)) {\n    if (key !== \"url\") problems.push(`unknown field ${JSON.stringify(key)}`);\n  }\n  if (typeof body.url !== \"string\") problems.push(\"url is required, as a string\");\n  else if (body.url.length > 2048) problems.push(\"url may be at most 2048 characters\");\n  else if (!isWebAddress(body.url)) problems.push(\"url must be an http or https address\");\n  return problems;\n}", "note": "**Every problem, not the first.** The function returns a list, and an empty list means the body is acceptable."},
 {"code": "function limitFrom(query, fallback = 20, most = 100) {\n  if (query.limit === undefined) return fallback;\n  const n = Number(query.limit);\n  if (!Number.isInteger(n) || n < 1 || n > most) return null;\n  return n;\n}", "note": "The limit of the section on the query string."},
 {"code": "links.param(\"code\", (req, res, next, code) => {\n  if (!isCode(code)) return res.status(400).json({ error: `${JSON.stringify(code)} is not a link code` });\n  next();\n});", "note": "The parameter check of this lesson's first section, for every route below that names `:code`."},
 {"code": "links\n  .route(\"/\")\n  .get(requireKey, async (req, res) => {\n    const limit = limitFrom(req.query);\n    if (limit === null) return res.status(400).json({ error: \"limit must be a whole number from 1 to 100\" });\n    res.set(\"cache-control\", \"no-store\").json((await store.all()).slice(0, limit));\n  })\n  .post(async (req, res) => {\n    const problems = problemsWith(req.body);\n    if (problems.length) return res.status(400).json({ error: \"the link was not created\", problems });\n    const link = await store.add(req.body.url);\n    res.status(201).location(`/links/${link.code}`).json(link);\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, POST\").status(405).json({ error: \"method not allowed\" }));", "note": "**The list is never cached** (`no-store`): it is the admin's view, and a copy left in a proxy or a browser would outlive the key that fetched it. Creating answers 400 with the whole list of problems."},
 {"code": "links\n  .route(\"/:code\")\n  .get(async (req, res) => {\n    const link = await store.find(req.params.code);\n    if (!link) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.json(link);\n  })\n  .delete(requireKey, async (req, res) => {\n    if (!(await store.remove(req.params.code))) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.status(204).end();\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, DELETE\").status(405).json({ error: \"method not allowed\" }));", "note": "One link, as in lesson 6."}
]}
```

With `server.js` running:

```
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"ur1": "https://example.com/"}' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["unknown field \"ur1\"","url is required, as a string"]}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": 42, "note": "hi"}' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["unknown field \"note\"","url is required, as a string"]}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '["https://example.com/"]' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["send a JSON object"]}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "ftp://example.com/file"}' http://127.0.0.1:3000/links
{"error":"the link was not created","problems":["url must be an http or https address"]}
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
201
```

**Each answer says what to fix, in the words of the field.** A client with three mistakes learns
about all three from one request, and nothing reached the store until there were none.

Written by hand, this is about twenty lines for one body with one field. A service with many bodies
uses a schema library instead — Zod, Ajv and Joi are the common ones — which describes the shape once
and produces the same list of problems from it. The rules above are the same with any of them: an
allowlist, types first, a limit on every length.
