---
title: Security headers, and sequence()
version: 1
---

**A response can carry headers that tell the browser to be stricter with it**, and `handle` sees every
response, which makes it the place to add them. Three are worth having on any site, and none needs
anything from the planner:

- **`X-Content-Type-Options: nosniff`** stops a browser from guessing that a file is a script or a
  stylesheet when the server said it was something else, which is how an uploaded "image" has been made
  to run as code.
- **`Referrer-Policy: same-origin`** keeps the planner's addresses, query and all, out of the
  `Referer` header sent to any other site a link leads to.
- **`X-Frame-Options: DENY`** forbids other sites from showing the planner inside a frame on their own
  page, where an invisible frame over a decoy button can make a person click "Mark done" without knowing.

They could go into the logging `handle`, but a hook that does two jobs is two jobs to read at once.
**`sequence()`**, from `@sveltejs/kit/hooks`, joins several `handle` functions into one: the first
receives the request, and its `resolve` calls the second, and so on, so that each wraps the ones after
it. Replace `src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';"},
 {"code": "async function log({ event, resolve }) {\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}", "note": "First in the sequence, so the time it measures includes everything after it."},
 {"code": "async function headers({ event, resolve }) {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n}\n\nexport const handle = sequence(log, headers);", "note": "Runs on the way out: `resolve` has produced the response, and the headers are added to it before it leaves."}
]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A request arrives at adapter-node. A request for a file, a prerendered page such as /about or something in static, is answered from disk straight away and never reaches the hooks. Every other request goes into handle, which is sequence(log, headers): log starts its clock and calls resolve, which calls headers, which calls SvelteKit&#x27;s own resolve to run the load functions, the action or the endpoint and render the page. The response comes back out through headers, which adds three headers, and through log, which prints a line, and leaves.\"><rect x=\"20\" y=\"120\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a request</text><text x=\"75\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">adapter-node</text><rect x=\"20\" y=\"220\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a file: /about, static/</text><text x=\"120\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sent from disk, no hooks</text><line x1=\"75\" y1=\"170\" x2=\"75\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"75.0,218.0 71.9,210.6 78.1,210.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"170\" y=\"20\" width=\"530\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">log</text><text x=\"688\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">starts a clock · prints a line</text><rect x=\"200\" y=\"52\" width=\"470\" height=\"140\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"212\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">headers</text><text x=\"658\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">adds three headers on the way out</text><rect x=\"230\" y=\"86\" width=\"410\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">resolve(event)</text><text x=\"435\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">load functions, the action or the endpoint</text><text x=\"435\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and the page rendered</text><line x1=\"130\" y1=\"145\" x2=\"168\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,145.0 160.6,148.1 160.6,141.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"435\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sequence(log, headers): each one wraps the ones after it</text></svg>", "caption": "A request goes in through each handle in order and comes back out the other way. Files the adapter serves itself never go in."}
```

Build, restart the server, and ask for the headers alone with `curl -I`:

```
ana@dev:~/planner$ curl -sI http://localhost:3000/
HTTP/1.1 200 OK
content-length: 6385
content-type: text/html
etag: "37nnea"
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: DENY
x-sveltekit-page: true
Date: Sat, 24 Oct 2026 01:02:30 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**And now About:**

```
ana@dev:~/planner$ curl -sI http://localhost:3000/about
HTTP/1.1 200 OK
etag: "CYq0Iz2pT0Oz5X-oveeKu9tTJbLWhkxwdMObAwLQBTQ"
vary: Accept-Encoding
content-length: 3254
accept-ranges: bytes
content-type: text/html;charset=utf-8
Date: Sat, 24 Oct 2026 01:02:30 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**None of the three.** About is a prerendered file, and `adapter-node` sends prerendered files and the
contents of `static` itself, without calling SvelteKit, so no hook ever sees those requests. The
documentation says so in a note, and it is the kind of note that is easy to read past: headers that
must be on every response belong in whatever serves the files, the proxy in front of the server in a
real deployment, or in a page that is not prerendered.

A stronger header than these three is **`Content-Security-Policy`**, which lists where scripts, styles
and images may come from, so that a script somebody manages to inject is refused by the browser. It is
harder to set by hand, because SvelteKit puts a small inline script in every page, the one lesson 15
read in the empty page; SvelteKit's own `csp` option writes the policy and marks its scripts so they are
allowed. It is beyond this lesson, and worth reading about in the documentation before a site goes live.
