---
title: Allocate, use, release
version: 1
---

Every value your program creates takes memory. **Allocating it is automatic, using it is your code,
and releasing it is the garbage collector's job.** The lab can show all three, with one switch meant
for experiments, `--expose-gc`, which lets a script run the collector on demand so that each figure is
taken after a collection:

```javascript
const mb = () => {
  globalThis.gc();
  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
};

console.log("at start:          ", mb(), "MB");

let books = Array.from({ length: 1_000_000 }, (_, i) => ({ id: i, title: `book ${i}` }));
console.log("a million books:   ", mb(), "MB");

books = null;
console.log("after letting go:  ", mb(), "MB");
```

```
ana@dev:~/js$ node --expose-gc lifecycle.js
at start:           3 MB
a million books:    80 MB
after letting go:   4 MB
```

**A million small objects took about 77 MB of the heap**, the part of memory where JavaScript objects
live. Setting `books` to `null` dropped the only reference to the array, and the next collection
reclaimed almost all of it. The program rounds to whole megabytes, because the exact figures move by a
few hundred kilobytes between runs.

Nothing called `free`. **The program's only job was to stop referring to the data**; the collector
noticed and did the rest.

## Where memory is reported

```javascript
const mb = (n) => `${Math.round(n / 1024 / 1024)} MB`;
const u = process.memoryUsage();
console.log("rss      ", mb(u.rss), "  everything the process holds");
console.log("heapTotal", mb(u.heapTotal), "  the heap V8 has reserved");
console.log("heapUsed ", mb(u.heapUsed), "  what live JavaScript objects use");
console.log("external ", mb(u.external), "  memory outside the heap, such as buffers");
```

```
ana@dev:~/js$ node --expose-gc usage.js
rss       40 MB   everything the process holds
heapTotal 5 MB   the heap V8 has reserved
heapUsed  4 MB   what live JavaScript objects use
external  1 MB   memory outside the heap, such as buffers
```

- **`heapUsed`** is the figure to watch for leaks in your own code: the memory taken by live JavaScript
  objects;
- `heapTotal` is what V8 has reserved for the heap, which it grows and shrinks as it sees fit;
- `rss`, resident set size, is everything the process holds, including Node itself and its code;
- `external` is memory held outside the heap on JavaScript's behalf, such as the bytes of a file
  read into a buffer.

In a browser, the **Memory panel** of the developer tools takes the place of these numbers, and lesson
22 opens the developer tools.
