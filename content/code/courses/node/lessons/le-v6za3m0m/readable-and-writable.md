---
title: Readable and writable streams
version: 1
---

**A readable stream produces data in pieces, called chunks; a writable stream consumes them.** A file
read with `createReadStream` is readable, a file written with `createWriteStream` is writable, and
lesson 5's request and response are one of each. Every stream is also an `EventEmitter`, and the events
say what is happening:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A file read as a stream: the readable hands over chunks of 64 KiB, one after another, to the code using them, with a data event for each, then end when the file is done, or error if something failed. Only one chunk is in the program&#x27;s hands at a time.\"><rect x=\"20\" y=\"50\" width=\"130\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">access.log</text><text x=\"85\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127 MB on disk</text><rect x=\"180\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"242\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"268\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"304\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"366\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"392\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"428\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"454\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><line x1=\"150\" y1=\"90\" x2=\"176\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"176.0,90.0 168.6,93.1 168.6,86.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"490\" y1=\"90\" x2=\"528\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"528.0,90.0 520.6,93.1 520.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"530\" y=\"50\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your code</text><text x=\"615\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one chunk at a time</text><text x=\"335\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">'data'  'data'  'data'  …  'end'</text><text x=\"335\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">or 'error', at any point</text></svg>", "caption": "The file is never in memory whole: a chunk is read, used and let go before the next one."}
```

```javascript
// chunks.js
import { createReadStream } from "node:fs";

const input = createReadStream("access.log");
let chunks = 0;
let bytes = 0;

input.on("data", (chunk) => {
  chunks++;
  bytes += chunk.length;
});
input.on("end", () => console.log(`${chunks} chunks, ${bytes} bytes, ${bytes / chunks} bytes a chunk`));
input.on("error", (err) => console.error(`could not read: ${err.code}`));
```

```
ana@dev:~/server/files$ node chunks.js
2024 chunks, 132612041 bytes, 65519.7831027668 bytes a chunk
```

**A file stream reads 64 kibibytes at a time**, 65 536 bytes, which is its `highWaterMark`; the last
chunk is whatever is left, so the average comes out a little under. Each chunk is a Buffer, bytes, as
the first section of this lesson said: a chunk boundary can fall in the middle of a line, or of a
character.

## Reading with for await

The `data` event is the old way to read, and it has a trap: it starts the flow as soon as a listener is
attached, whether you are ready or not. **A readable stream is also an async iterable**, and
`for await` reads it one chunk at a time, waiting for each loop to finish before asking for the next:

```javascript
// iterate.js
import { createReadStream } from "node:fs";

let longest = 0;
for await (const chunk of createReadStream("access.log", { highWaterMark: 1024 * 1024 })) {
  longest = Math.max(longest, chunk.length);
}
console.log(`largest chunk: ${longest} bytes`);
```

```
ana@dev:~/server/files$ node iterate.js
largest chunk: 1048576 bytes
```

The `highWaterMark` option chose the chunk size, a mebibyte this time. **`for await` is how this course
reads streams**, as lesson 5 read a request body: errors arrive as exceptions in the loop, and the
reading never runs ahead of the code using it.

## Writing

```javascript
// write.js
import { createWriteStream } from "node:fs";
import { once } from "node:events";

const out = createWriteStream("numbers.txt");
for (let i = 1; i <= 3; i++) out.write(`line ${i}\n`);
out.end("the end\n");
await once(out, "finish");
console.log("finished, and the file is closed");
```

```
ana@dev:~/server/files$ node write.js && cat numbers.txt
finished, and the file is closed
line 1
line 2
line 3
the end
```

`write` hands a chunk to the stream; `end` hands the last one and says there are no more; `finish` fires
when everything has reached the file. **A program that exits before `finish` may lose the end of what
it wrote**, which is why the last lines wait for it.
