---
title: The links service, with nothing installed
version: 1
---

**Everything in this lesson, put together, is a working link shortener in one file.** It keeps its
links in a `Map`, so they last as long as the process does; lesson 8 gives it a file. Save it as
`~/server/native/server.js`:

```schooling-example
{"language": "javascript", "file": "server.js", "parts": [
 {"code": "// server.js: the links service with nothing but node:http.\nimport http from \"node:http\";\nimport { randomInt } from \"node:crypto\";\n\nconst ALPHABET = \"23456789abcdefghjkmnpqrstuvwxyz\";\nconst links = new Map(); // code -> { code, url, visits, created }\n\nfunction makeCode() {\n  let code;\n  do {\n    code = Array.from({ length: 6 }, () => ALPHABET[randomInt(ALPHABET.length)]).join(\"\");\n  } while (links.has(code));\n  return code;\n}", "note": "The alphabet of lesson 4's `src/code.js`, and the store: a `Map` from a code to its link. A new code is drawn again if it is already taken, which at 890 million codes almost never happens and costs nothing to check."},
 {"code": "function send(res, status, body, headers = {}) {\n  const text = body === undefined ? \"\" : JSON.stringify(body) + \"\\n\";\n  res.writeHead(status, {\n    ...(text && { \"content-type\": \"application/json; charset=utf-8\" }),\n    \"content-length\": Buffer.byteLength(text),\n    ...headers,\n  });\n  res.end(text);\n}", "note": "**One function writes every reply**, so every reply has the same headers: a JSON type when there is a body, a `content-length` counted in bytes, and whatever the route adds."},
 {"code": "class HttpError extends Error {\n  constructor(status, message) {\n    super(message);\n    this.status = status;\n  }\n}", "note": "An error that carries its status. A route throws one when the client asked for something wrong, and the edge of the server turns it into a reply."},
 {"code": "async function readJson(req, limit = 1024) {\n  if (!(req.headers[\"content-type\"] || \"\").startsWith(\"application/json\")) {\n    throw new HttpError(415, \"send JSON, with content-type: application/json\");\n  }\n  const chunks = [];\n  let size = 0;\n  for await (const chunk of req) {\n    size += chunk.length;\n    if (size > limit) throw new HttpError(413, `a body may be at most ${limit} bytes`);\n    chunks.push(chunk);\n  }\n  try {\n    return JSON.parse(Buffer.concat(chunks).toString(\"utf8\"));\n  } catch {\n    throw new HttpError(400, \"the body is not valid JSON\");\n  }\n}", "note": "The three checks of the section on reading a body, now throwing instead of returning."},
 {"code": "function isWebAddress(text) {\n  try {\n    const url = new URL(text);\n    return url.protocol === \"http:\" || url.protocol === \"https:\";\n  } catch {\n    return false;\n  }\n}", "note": "**The service redirects to whatever it stored**, so it stores only web addresses. A `javascript:` or `file:` URL saved here would be handed to every browser that follows the link."},
 {"code": "async function handle(req, res) {\n  const { pathname } = new URL(req.url, \"http://localhost\");\n  const parts = pathname.split(\"/\").filter(Boolean).map(decodeURIComponent);\n\n  if (parts.length === 1 && parts[0] === \"links\") {\n    if (req.method === \"GET\") return send(res, 200, [...links.values()]);\n    if (req.method === \"POST\") {\n      const body = await readJson(req);\n      if (!isWebAddress(body?.url)) throw new HttpError(400, \"url must be an http or https address\");\n      const link = { code: makeCode(), url: body.url, visits: 0, created: new Date().toISOString() };\n      links.set(link.code, link);\n      return send(res, 201, link, { location: `/links/${link.code}` });\n    }\n    return send(res, 405, { error: \"method not allowed\" }, { allow: \"GET, POST\" });\n  }", "note": "The routes, by the number of parts in the path and the method. `/links` lists and creates; a new link answers 201 with a `location` saying where it now lives."},
 {"code": "  if (parts.length === 2 && parts[0] === \"links\") {\n    const link = links.get(parts[1]);\n    if (!link) throw new HttpError(404, `no link ${parts[1]}`);\n    if (req.method === \"GET\") return send(res, 200, link);\n    if (req.method === \"DELETE\") {\n      links.delete(link.code);\n      return send(res, 204);\n    }\n    return send(res, 405, { error: \"method not allowed\" }, { allow: \"GET, DELETE\" });\n  }", "note": "`/links/:code` reads and deletes one link. A 204 has no body, so `send` writes neither a type nor any text."},
 {"code": "  if (parts.length === 1 && req.method === \"GET\") {\n    const link = links.get(parts[0]);\n    if (!link) throw new HttpError(404, `no link ${parts[0]}`);\n    link.visits++;\n    return send(res, 302, undefined, { location: link.url });\n  }\n\n  throw new HttpError(404, `nothing at ${pathname}`);\n}", "note": "**The short link itself**, `/:code`: count the visit and answer 302 with the address in `location`, which a browser follows on its own."},
 {"code": "const server = http.createServer(async (req, res) => {\n  try {\n    await handle(req, res);\n  } catch (err) {\n    if (err instanceof URIError) err = new HttpError(400, \"the path is not valid percent-encoding\");\n    if (!(err instanceof HttpError)) console.error(err);\n    const status = err instanceof HttpError ? err.status : 500;\n    send(res, status, { error: status === 500 ? \"internal error\" : err.message });\n  }\n  console.log(`${req.method} ${req.url} ${res.statusCode}`);\n});\n\nserver.listen(3000, \"127.0.0.1\", () => console.log(\"links on http://127.0.0.1:3000\"));", "note": "The edge. Every error becomes a reply: an `HttpError` says its own status, a bad percent-encoding is the client's 400, and anything else is logged in full and answered with a short 500. One line of log per request, after the reply."}
]}
```

## Using it

Start it in one terminal, and create a link from the other. `-i` shows the status and the headers,
which is where the answer is:

```
ana@dev:~/server/native$ curl -si -H 'content-type: application/json' -d '{"url": "https://nodejs.org/docs/latest-v22.x/api/"}' http://127.0.0.1:3000/links
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8
content-length: 116
location: /links/tmmzw8
Date: Fri, 16 Oct 2026 23:08:54 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"code":"tmmzw8","url":"https://nodejs.org/docs/latest-v22.x/api/","visits":0,"created":"2026-10-16T23:08:54.326Z"}
```

Now follow it, list the links, and ask for things that are not there:

```
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/tmmzw8 | head -3
HTTP/1.1 302 Found
content-length: 0
location: https://nodejs.org/docs/latest-v22.x/api/
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/tmmzw8
{"code":"tmmzw8","url":"https://nodejs.org/docs/latest-v22.x/api/","visits":1,"created":"2026-10-16T23:08:54.326Z"}
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/nope22
{"error":"no link nope22"}
ana@dev:~/server/native$ curl -si -X PUT http://127.0.0.1:3000/links | head -1
HTTP/1.1 405 Method Not Allowed
ana@dev:~/server/native$ curl -s -H 'content-type: application/json' -d '{"url": "javascript:alert(1)"}' http://127.0.0.1:3000/links
{"error":"url must be an http or https address"}
ana@dev:~/server/native$ curl -si -X DELETE http://127.0.0.1:3000/links/tmmzw8 | head -1
HTTP/1.1 204 No Content
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links
[]
```

**The visit was counted, and every mistake got its own status and a sentence.** The `javascript:` URL
was refused by `isWebAddress`, which is the defence the service most needs: a shortener that stored
any URL would turn every short link into a way to hand a browser something other than a web page.

The server's terminal has one line per request:

```
ana@dev:~/server/native$ node server.js
links on http://127.0.0.1:3000
POST /links 201
GET /links 200
GET /tmmzw8 302
GET /links/tmmzw8 200
GET /links/nope22 404
PUT /links 405
POST /links 400
DELETE /links/tmmzw8 204
GET /links 200
^C
```

That is a complete service in about 110 lines, and it is also the list of what Express does for you:
the routing table, `send`, `readJson`, the 404 and 405, the edge that turns errors into replies.
Lesson 6 writes the same service again, in a fraction of the code, and every piece of this file has a
named counterpart there.
