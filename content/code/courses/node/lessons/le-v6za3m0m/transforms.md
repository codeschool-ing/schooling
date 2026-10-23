---
title: Transforms, and reading line by line
version: 1
---

**A transform is a stream that is writable on one side and readable on the other**, changing what
passes through. `createGzip` was one. Writing your own takes one function, `transform`, called once
per chunk:

```schooling-example
{"language": "javascript", "file": "report.js", "parts": [
 {"code": "import { createReadStream } from \"node:fs\";\nimport { createInterface } from \"node:readline\";\nimport { Readable, Transform, Writable } from \"node:stream\";\nimport { pipeline } from \"node:stream/promises\";\n\nconst lines = Readable.from(createInterface({ input: createReadStream(\"access.log\"), crlfDelay: Infinity }));", "note": "**Lines from chunks.** `readline` keeps the end of each chunk until the next one completes the line, so a line cut across two chunks arrives whole, the problem the section on buffers raised."},
 {"code": "const slowOnes = new Transform({\n  objectMode: true,\n  transform(line, encoding, done) {\n    const [time, method, path, status, ms] = line.split(\" \");\n    if (parseInt(ms, 10) >= 990) this.push({ time, method, path, status: Number(status), ms: parseInt(ms, 10) });\n    done();\n  },\n});", "note": "**A transform in object mode** receives each line as a string and passes on only the slow requests, turned into objects. `this.push` sends something on; not calling it drops the line."},
 {"code": "const byPath = {};\nconst tally = new Writable({\n  objectMode: true,\n  write(request, encoding, done) {\n    byPath[request.path] = (byPath[request.path] ?? 0) + 1;\n    done();\n  },\n});\n\nawait pipeline(lines, slowOnes, tally);\nconsole.log(byPath);", "note": "**The end of the pipeline counts by path.** A writable in object mode, too: the last stage, where the data stops."}
]}
```

```
ana@dev:~/server/files$ node report.js
{
  '/links': 1722,
  '/nothing': 10313,
  '/qh95f4': 9171,
  '/links/7ctxqn': 2869,
  '/7ctxqn': 6302
}
```

The three million lines went through in pieces, and what came out was a five-line report. **That is the
shape of every stream program**: a source, a few small stages that each do one thing, and a
destination, with `pipeline` holding them together and backpressure flowing back from the slowest.

`objectMode` is what lets a stream carry strings and objects rather than bytes. A transform in object
mode counts its buffer in objects, sixteen by default, instead of bytes.
