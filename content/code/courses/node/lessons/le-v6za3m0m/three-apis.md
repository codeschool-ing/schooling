---
title: Three ways to read a file
version: 1
---

**`node:fs` offers every operation in three forms**, and lesson 2 already explained what separates
them: where the waiting happens.

| form | how it looks | where it waits |
|---|---|---|
| synchronous | `fs.readFileSync(path)` returns the contents | on the main thread, blocking everything |
| callback | `fs.readFile(path, (err, data) => …)` | on the thread pool; the callback runs later |
| promise | `await readFile(path)` from `node:fs/promises` | on the thread pool; the promise settles later |

The same read in all three, with a line printed after each call starts:

```javascript
// three.js
import fs from "node:fs";
import { readFile } from "node:fs/promises";

const name = new URL(import.meta.url).pathname;

const a = fs.readFileSync(name, "utf8");
console.log(`1. sync: ${a.length} characters, already here`);

fs.readFile(name, "utf8", (err, b) => {
  if (err) throw err;
  console.log(`4. callback: ${b.length} characters`);
});
console.log("2. the callback read has started");

const pending = readFile(name, "utf8");
console.log("3. the promise read has started");
console.log(`5. promise: ${(await pending).length} characters`);
```

```
ana@dev:~/server/files$ node three.js
1. sync: 560 characters, already here
2. the callback read has started
3. the promise read has started
4. callback: 560 characters
5. promise: 560 characters
```

The synchronous read finished before the next line ran. The other two started, the program went on,
and their results arrived afterwards, in the order the pool finished them. **This course uses the
promise form**, `node:fs/promises`, for everything after start-up: it reads like synchronous code
with `await`, errors arrive as exceptions a `try` can catch, and it never blocks the loop. The
callback form is what older code and older documentation use, and it does the same work.
