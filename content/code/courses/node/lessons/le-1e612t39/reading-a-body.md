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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A request body passing three checks in order. First the content-type: anything but JSON is answered 415 before a byte is read. Then the size, counted as the pieces arrive: past the limit, 413. Then the parse, once every piece is in: bad JSON is 400. A body that passes all three is the parsed value, and the answer is 200.\"><rect x=\"20\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what it claims</text><text x=\"95\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">content-type</text><line x1=\"170\" y1=\"80\" x2=\"198\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,80.0 190.6,83.1 190.6,76.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"95\" y1=\"110\" x2=\"95\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,150.0 91.9,142.6 98.1,142.6\" fill=\"var(--amber)\"></polygon><text x=\"95\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">415</text><rect x=\"200\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">how big it is</text><text x=\"275\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">counted per piece</text><line x1=\"350\" y1=\"80\" x2=\"378\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,80.0 370.6,83.1 370.6,76.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"275\" y1=\"110\" x2=\"275\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"275.0,150.0 271.9,142.6 278.1,142.6\" fill=\"var(--amber)\"></polygon><text x=\"275\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">413</text><rect x=\"380\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">whether it parses</text><text x=\"455\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON.parse</text><line x1=\"530\" y1=\"80\" x2=\"558\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,80.0 550.6,83.1 550.6,76.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"455\" y1=\"110\" x2=\"455\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,150.0 451.9,142.6 458.1,142.6\" fill=\"var(--amber)\"></polygon><text x=\"455\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">400</text><rect x=\"560\" y=\"50\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the value</text><text x=\"630\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the request arrives</text><text x=\"290\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">each refusal has its own status code</text></svg>", "caption": "Cheapest first: the type costs nothing to check, the size is checked while reading, the parse comes last."}
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
