---
title: Reading a body
version: 1
---

**The body of a request is not on the request object; it arrives on it, in pieces, after your
handler has been called.** The request is a readable stream, and `for await` reads it piece by piece.
A server that reads JSON has three checks to make, and each one has its own status code:

```schooling-example
{"language": "javascript", "file": "body.js", "parts": [
 {"code": "import http from \"node:http\";\n\nasync function readJson(req, limit = 1024) {\n  if (!(req.headers[\"content-type\"] || \"\").startsWith(\"application/json\")) {\n    return { status: 415, error: \"send JSON, with content-type: application/json\" };\n  }", "note": "**What it claims to be.** A client says what it is sending in `content-type`. Anything that is not JSON is refused before a byte of it is read: 415, Unsupported Media Type."},
 {"code": "  const chunks = [];\n  let size = 0;\n  for await (const chunk of req) {\n    size += chunk.length;\n    if (size > limit) return { status: 413, error: `a body may be at most ${limit} bytes` };\n    chunks.push(chunk);\n  }", "note": "**How big it is.** The pieces are Buffers. Counting them as they arrive stops a client that sends a gigabyte before the gigabyte is in memory: 413, Content Too Large."},
 {"code": "  try {\n    return { value: JSON.parse(Buffer.concat(chunks).toString(\"utf8\")) };\n  } catch {\n    return { status: 400, error: \"the body is not valid JSON\" };\n  }\n}", "note": "**Whether it parses.** Only once every piece is in is the text decoded and parsed; a piece can end in the middle of a character. Bad JSON is the client's mistake: 400."},
 {"code": "http\n  .createServer(async (req, res) => {\n    const body = await readJson(req);\n    res.statusCode = body.status ?? 200;\n    res.end(JSON.stringify(body.error ? { error: body.error } : { received: body.value }) + \"\\n\");\n  })\n  .listen(3000, \"127.0.0.1\");", "note": "The handler waits for the body, then answers with what it found."}
]}
```

Four requests, one for each outcome. `-d` makes `curl` send a body, and `-H` sets its type:

```
ana@dev:~/server/native$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/
{"received":{"url":"https://example.com/"}}
ana@dev:~/server/native$ curl -s -d 'url=https://example.com/' http://127.0.0.1:3000/
{"error":"send JSON, with content-type: application/json"}
ana@dev:~/server/native$ curl -s -H 'content-type: application/json' -d '{"url": ' http://127.0.0.1:3000/
{"error":"the body is not valid JSON"}
ana@dev:~/server/native$ head -c 2000 /dev/zero | tr '\0' 'a' | curl -s -H 'content-type: application/json' -d @- http://127.0.0.1:3000/
{"error":"a body may be at most 1024 bytes"}
```

The limit is the line in this section that a server forgets. **Without it, the size of a request is
the client's decision**, and a few clients each sending a large body can fill the process's memory.
1024 bytes is plenty for a link; Express's own JSON parser, in lesson 7, defaults to 100 kilobytes,
and every service should choose its own number on purpose.

The fourth request sent 2000 bytes, and the answer came back at once, after the first piece that
went over. `head -c 2000 /dev/zero | tr '\0' 'a'` is a way to make two thousand `a`s without typing
them, and `-d @-` tells curl to read the body from what is piped into it.
