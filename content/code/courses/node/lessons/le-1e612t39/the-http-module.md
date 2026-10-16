---
title: What node:http gives you
version: 1
---

**`node:http` turns bytes on a socket into two objects and hands them to your function: the
request, which you read, and the response, which you write.** Everything else in this lesson, and
everything Express does in lessons 6 and 7, is built on those two objects.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The bytes of one request on the socket, in time order: the request line, the headers, then two pieces of body. As soon as the headers are complete, Node calls your handler with req and res. The body pieces arrive afterwards and are read from req as a stream. The handler writes the reply to res, which goes back over the same socket.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bytes arriving on the socket</text><rect x=\"20\" y=\"36\" width=\"144\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /links HTTP/1.1</text><rect x=\"174\" y=\"36\" width=\"144\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"246.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">headers</text><rect x=\"330\" y=\"36\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"387.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">body, piece 1</text><rect x=\"460\" y=\"36\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"517.0\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">body, piece 2</text><line x1=\"20\" y1=\"80\" x2=\"700\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,80.0 692.6,83.1 692.6,76.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><line x1=\"322\" y1=\"66\" x2=\"322\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"150\" y=\"120\" width=\"280\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the 'request' event</text><text x=\"290\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">handler(req, res)</text><text x=\"330\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">headers complete</text><path d=\"M391 66 C 391 100, 451 110, 481 140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"479\" y1=\"137\" x2=\"481\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"481.0,140.0 474.3,135.6 479.5,132.1\" fill=\"var(--phosphor)\"></polygon><path d=\"M521 66 C 521 100, 581 110, 611 140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"609\" y1=\"137\" x2=\"611\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"611.0,140.0 604.3,135.6 609.5,132.1\" fill=\"var(--phosphor)\"></polygon><rect x=\"500\" y=\"140\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">for await (chunk of req)</text><rect x=\"150\" y=\"210\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">res.writeHead(…)   res.end(…)</text><line x1=\"290\" y1=\"174\" x2=\"290\" y2=\"208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"290.0,208.0 286.9,200.6 293.1,200.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"440\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">back over the same socket</text></svg>", "caption": "Your handler runs when the headers are in, before the body. The body is read from req as it arrives."}
```

In order, for one request:

1. A client opens a TCP connection to the port the server listens on. libuv hands the socket to the
   loop, as lesson 2 showed, and no thread waits on it.
2. Bytes arrive. **llhttp**, the parser built into Node, reads the request line and the headers.
3. As soon as the headers are complete — **before the body has arrived** — Node creates an
   `http.IncomingMessage` and an `http.ServerResponse` and emits the server's `'request'` event,
   which calls your function with both.
4. Your function reads what it needs from the request, decides, and writes the status, the headers
   and the body to the response.
5. `res.end()` finishes the reply. The connection stays open for the client's next request, unless
   either side says otherwise.

Step 3 has a consequence lesson 8 builds on: **the request is a readable stream and the response is
a writable stream.** The body arrives in pieces, after your function has already been called, and you
read it as it comes, which the section on reading a body does. A reply can be written in pieces too.

## What it does not give you

`node:http` parses the protocol and nothing more. There is no routing: every request, for every path
and every method, arrives at the same function. There is no body parsing, no JSON, no cookies, no
static files, no errors turned into responses. **That is what this lesson writes by hand**, in a
little over a hundred lines, so that lesson 6 can show exactly which of those lines Express writes for
you. The service is the link shortener of lesson 3's layout, built in its own folder,
`~/server/native`, with no `package.json` dependencies at all.
