---
title: Why streams exist
version: 1
---

**`readFile` holds the whole file in memory; a stream holds a piece of it at a time.** For a small
file the difference is nothing. For a large one it is the difference between a server that answers
and one that runs out of memory, and it is easy to measure.

First, something large. This program writes an access log, three million lines that are the same on
every run, about 130 megabytes:

```javascript
// makelog.js: write an access log of N lines, the same every time.
import { createWriteStream } from "node:fs";
import { once } from "node:events";

const n = Number(process.argv[2] ?? 3_000_000);
const out = createWriteStream("access.log");
const paths = ["/links", "/7ctxqn", "/links/7ctxqn", "/qh95f4", "/nothing"];
const statuses = [200, 302, 200, 302, 404];
let seed = 42;
const next = () => (seed = (seed * 1103515245 + 12345) % 2147483648);

for (let i = 0; i < n; i++) {
  const k = next() % paths.length;
  const line = `2026-10-01T12:00:${String(i % 60).padStart(2, "0")}Z GET ${paths[k]} ${statuses[k]} ${(next() % 900) + 100}ms\n`;
  if (!out.write(line)) await once(out, "drain");
}
out.end();
await once(out, "finish");
console.log(`wrote ${n} lines`);
```

It writes with a stream already, and the `drain` line in it is the subject of the section on
backpressure. Now two programs that count the 404s in it, one with `readFile` and one with a stream:

```javascript
// whole.js
import { readFile } from "node:fs/promises";

const text = await readFile("access.log", "utf8");
let missing = 0;
for (const line of text.split("\n")) if (line.includes(" 404 ")) missing++;
console.log(`${missing} not found; peak memory ${Math.round(process.resourceUsage().maxRSS / 1024)} MB`);
```

```javascript
// streamed.js
import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";

let missing = 0;
for await (const line of createInterface({ input: createReadStream("access.log"), crlfDelay: Infinity })) {
  if (line.includes(" 404 ")) missing++;
}
console.log(`${missing} not found; peak memory ${Math.round(process.resourceUsage().maxRSS / 1024)} MB`);
```

`maxRSS` is the most memory the process held at any moment, which the operating system measured.

```
ana@dev:~/server/files$ node makelog.js && ls -lh access.log
wrote 3000000 lines
-rw-r--r-- 1 ana ana 127M Oct 22 19:16 access.log
ana@dev:~/server/files$ node whole.js
610582 not found; peak memory 453 MB
ana@dev:~/server/files$ node streamed.js
610582 not found; peak memory 80 MB
```

**Same answer, a fraction of the memory.** `whole.js` held the file as one string and then an array of
three million strings; `streamed.js` never held more than a piece of 64 kilobytes and the line being
looked at. The difference grows with the file and the stream's does not: a log ten times larger costs
`whole.js` ten times the memory, and on a server with ten such requests at once that is the process
killed for running out of it.
