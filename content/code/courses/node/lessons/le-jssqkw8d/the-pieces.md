---
title: What Node is made of
version: 1
---

**Node is not one program but three, glued together.** Knowing which part does what answers the questions the rest of this lesson asks. Why can one request
stop all the others? Why do a password hash and a file read wait in the same queue? And why do a
hundred open connections cost no threads at all?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Node in layers. At the top, your JavaScript and Node&#x27;s library run on V8, on the main thread. Below them the C++ bindings, then libuv with its event loop on the same main thread and a thread pool of four. At the bottom, the operating system, which watches sockets and timers for the loop and does file reads for the pool.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">your JavaScript</text><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">node:http   node:fs   node:crypto   …</text><rect x=\"20\" y=\"82\" width=\"330\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">V8</text><text x=\"185\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compiles and runs it; owns the heap</text><rect x=\"370\" y=\"82\" width=\"330\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">bindings (C++)</text><text x=\"535\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">where a call stops being JavaScript</text><rect x=\"20\" y=\"144\" width=\"680\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">libuv</text><rect x=\"40\" y=\"174\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">the event loop</text><text x=\"190\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on the main thread, with V8</text><rect x=\"380\" y=\"174\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the thread pool</text><rect x=\"452\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"492\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"532\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"572\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"254\" width=\"680\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the operating system</text><text x=\"190\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">watches sockets and timers (epoll)</text><text x=\"530\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads files, resolves names</text><line x1=\"190\" y1=\"236\" x2=\"190\" y2=\"252\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,252.0 186.9,244.6 193.1,244.6\" fill=\"var(--amber)\"></polygon><line x1=\"530\" y1=\"236\" x2=\"530\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"530.0,252.0 526.9,244.6 533.1,244.6\" fill=\"var(--wire)\"></polygon></svg>", "caption": "Your code and the loop share one thread. The pool's four threads never run JavaScript."}
```

From the top:

- **V8** is the JavaScript engine, the same one Chromium uses. It compiles your code and runs it,
  and it owns the heap where your objects live. It knows nothing about files or sockets: on its own,
  JavaScript cannot even set a timer.
- **Node's own library**, everything you import as `node:something`, is written partly in
  JavaScript and partly in C++. The C++ half, the *bindings*, is where a call such as
  `fs.readFile` stops being JavaScript and becomes a request to the layer below.
- **libuv** is a C library that gives Node its **event loop** and a **thread pool**. It asks the
  operating system to watch sockets and timers, and when the system has no way to do something
  without blocking, such as reading most files, it does it on one of the pool's threads instead.

Your Node says which version of each it was built with:

```
ana@dev:~/server/loop$ node -p process.versions
{
  node: '22.22.0',
  acorn: '8.15.0',
  ada: '2.9.2',
  amaro: '1.1.4',
  ares: '1.34.6',
  brotli: '1.1.0',
  cjs_module_lexer: '2.1.0',
  cldr: '47.0',
  icu: '77.1',
  llhttp: '9.3.0',
  modules: '127',
  napi: '10',
  nbytes: '0.1.1',
  ncrypto: '0.0.1',
  nghttp2: '1.64.0',
  openssl: '3.5.4',
  simdjson: '3.13.0',
  simdutf: '6.4.2',
  sqlite: '3.50.4',
  tz: '2025b',
  undici: '6.23.0',
  unicode: '16.0',
  uv: '1.51.0',
  uvwasi: '0.0.23',
  v8: '12.4.254.21-node.33',
  zlib: '1.3.1-470d3a2',
  zstd: '1.5.7'
}
```

`v8` and `uv` are the two pieces above. The rest are libraries Node carries inside it: `openssl`
for TLS and `crypto`, `zlib` for compression in lesson 8, `llhttp` the parser that reads an HTTP
request in lesson 5, `undici` the client behind `fetch`. **None of them is installed separately**;
they arrived in the tarball you unpacked in lesson 1.

## One thread for your code

The part that matters most for everything else: **V8 runs your JavaScript on one thread**, the
main thread, and libuv's loop runs on that same thread. When the loop has a callback ready, it
calls it, V8 runs it to the end, and only then does the loop look for the next one. The pool's
threads never run JavaScript. They do the C work underneath a few of Node's functions and hand the
result back to the loop, which then calls your callback on the main thread.

So "Node is single-threaded" is half true. Your code is. The process is not, and a section below
counts its threads.
