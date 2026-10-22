---
title: Backpressure, or why write returns a boolean
version: 1
---

**When a producer is faster than a consumer, the data between them has to wait somewhere, and
backpressure is the consumer saying "stop until I catch up".** In Node it is one boolean: `write()`
returns `false` when the stream's buffer is full, and the stream emits `drain` when it has room again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A fast producer writes into a slow consumer&#x27;s buffer. When the buffer passes its high-water mark, write returns false; a producer that waits for drain keeps the buffer at that level, while one that ignores it lets the buffer grow without limit.\"><rect x=\"20\" y=\"70\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">producer</text><text x=\"85\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fast</text><rect x=\"570\" y=\"70\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">consumer</text><text x=\"635\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">slow</text><rect x=\"210\" y=\"70\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the stream's buffer</text><rect x=\"212\" y=\"72\" width=\"150\" height=\"66\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><line x1=\"362\" y1=\"66\" x2=\"362\" y2=\"144\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"362\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">highWaterMark</text><line x1=\"150\" y1=\"105\" x2=\"208\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,105.0 200.6,108.1 200.6,101.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"179\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">write()</text><line x1=\"512\" y1=\"105\" x2=\"568\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,105.0 560.6,108.1 560.6,101.9\" fill=\"var(--paper-dim)\"></polygon><path d=\"M360 170 C 360 205, 85 205, 85 142\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"85\" y1=\"150\" x2=\"85\" y2=\"142\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"85.0,142.0 88.1,149.4 81.9,149.4\" fill=\"var(--amber)\"></polygon><text x=\"230\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">past the mark: write() returns false; wait for 'drain'</text></svg>", "caption": "Backpressure is the consumer's buffer saying it is full, and the producer waiting until it is not."}
```

A writable that is deliberately slow, and a producer that ignores the boolean:

```schooling-example
{"language": "javascript", "file": "pressure.js", "parts": [
 {"code": "import { Writable } from \"node:stream\";\nimport { once } from \"node:events\";\n\nfunction slowSink() {\n  return new Writable({\n    highWaterMark: 16 * 1024,\n    write(chunk, encoding, done) {\n      setTimeout(done, 1);\n    },\n  });\n}\n\nconst chunk = Buffer.alloc(1024, \"a\");\nconst mb = (n) => `${Math.round(n / 1024 / 1024)} MB`;", "note": "**A slow consumer**: it takes a millisecond per chunk, and holds at most 16 kibibytes, its `highWaterMark`, before saying it is full."},
 {"code": "const careless = slowSink();\nfor (let i = 0; i < 5000; i++) careless.write(chunk);\nconsole.log(`ignoring false: ${mb(careless.writableLength)} waiting in memory`);\ncareless.destroy();", "note": "**Ignoring it.** Five thousand chunks written in one go: every one is accepted into memory, and the buffer grows to the whole five megabytes."},
 {"code": "const careful = slowSink();\nlet most = 0;\nfor (let i = 0; i < 5000; i++) {\n  if (!careful.write(chunk)) await once(careful, \"drain\");\n  most = Math.max(most, careful.writableLength);\n}\nconsole.log(`respecting it: at most ${most} bytes waiting`);\ncareful.end();", "note": "**Respecting it.** When `write` says `false`, wait for `drain`. The buffer never holds more than its high-water mark."}
]}
```

```
ana@dev:~/server/files$ node pressure.js
ignoring false: 5 MB waiting in memory
respecting it: at most 15360 bytes waiting
```

**Ignoring the boolean does not lose data, it hides it in memory**, and with a producer that never
ends, a log copied to a slow disk, a download sent to a slow phone, the memory grows until the process
dies. Respecting it keeps a few kibibytes in flight whatever the sizes involved.

`makelog.js` in the section on why streams respects it: `if (!out.write(line)) await once(out,
"drain")`. **`pipeline` and `for await` do this for you**, which is the strongest reason to use them;
the place you meet backpressure by hand is a loop that calls `write` itself.
