---
title: pipeline, which connects streams and cleans up
version: 1
---

**Most stream code moves data from one stream to another, possibly changing it on the way**, and
`pipeline` from `node:stream/promises` does exactly that: it connects a readable, any number of
transforms, and a writable, and returns a promise that settles when the last one finishes, or rejects
with the first error from any of them.

```javascript
// gzip.js: compress a file, and say how much it saved.
import { createReadStream, createWriteStream } from "node:fs";
import { stat } from "node:fs/promises";
import { pipeline } from "node:stream/promises";
import { createGzip } from "node:zlib";

const [from, to] = process.argv.slice(2);
try {
  await pipeline(createReadStream(from), createGzip(), createWriteStream(to));
  const [a, b] = [(await stat(from)).size, (await stat(to)).size];
  console.log(`${a} bytes became ${b}, ${((100 * b) / a).toFixed(1)}%`);
} catch (err) {
  console.error(`could not compress ${from}: ${err.code}`);
  process.exitCode = 1;
}
```

```
ana@dev:~/server/files$ node gzip.js access.log access.log.gz
132612041 bytes became 13253185, 10.0%
ana@dev:~/server/files$ ls -lh access.log access.log.gz
-rw-r--r-- 1 ana ana 127M Oct 22 19:16 access.log
-rw-r--r-- 1 ana ana  13M Oct 22 19:16 access.log.gz
```

The log compressed to a small share of its size, because three million lines that differ in a few
characters are mostly repetition. `createGzip()` is a **transform**: writable on one side, readable on
the other, the subject of the section after next. And **the memory stayed flat**, a chunk at a time
through all three.

## Why not .pipe()

Older code writes `source.pipe(gzip).pipe(out)`, and it works until something fails. `.pipe` passes
data along and passes **no errors**: if the source cannot be read, the writable is left open, the
file half made, and the error, unless you listen for it on every stream separately, goes nowhere.
`pipeline` destroys every stream in the chain when one of them fails, and gives you the error once:

```
ana@dev:~/server/files$ node gzip.js missing.log missing.log.gz; echo "exit code $?"; ls -l missing.log.gz
could not compress missing.log: ENOENT
exit code 1
-rw-r--r-- 1 ana ana 0 Oct 22 19:16 missing.log.gz
```

The error arrived as an exception with its code, the program ended with exit code 1. The empty
`missing.log.gz` is the one thing `pipeline` cannot undo: the writable had already created the file
before the readable failed. A program that must leave nothing behind writes to a temporary name and
renames it at the end, the trick of the section on writing a file that survives a crash.
