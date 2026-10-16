---
title: The thread pool
version: 1
---

**Some of Node's functions cannot be done without blocking, so libuv does them on a pool of four
threads.** Your callback still runs on the main thread; only the C work underneath happens on the
pool. Four groups of functions use it:

| what | why it needs a thread |
|---|---|
| most of `node:fs` | Linux offers no general way to read a file without waiting |
| `crypto.pbkdf2`, `scrypt`, `randomBytes` and a few others | they are pure computation, and long |
| `zlib`, the compression of lesson 8, in its callback form | the same |
| `dns.lookup`, which `http.get("http://example.com")` uses | it calls the system's resolver, which blocks |

Network sockets are not in the table, and the next section is about why.

## Four at a time

`pbkdf2` stretches a password into a key by hashing it many times over, which is what a server does
when somebody signs in. This program asks for several at once and prints when each one finishes:

```javascript
// pool.js: hash a password N times at once and say when each one finished.
const crypto = require("node:crypto");

const n = Number(process.argv[2] || 4);
const start = performance.now();
for (let i = 1; i <= n; i++) {
  crypto.pbkdf2("correct horse", "salt", 1_000_000, 64, "sha512", () => {
    console.log(`hash ${i} done at ${Math.round(performance.now() - start)} ms`);
  });
}
```

```
ana@dev:~/server/loop$ node pool.js 1
hash 1 done at 425 ms
ana@dev:~/server/loop$ node pool.js 4
hash 1 done at 423 ms
hash 3 done at 425 ms
hash 2 done at 445 ms
hash 4 done at 453 ms
ana@dev:~/server/loop$ node pool.js 6
hash 2 done at 426 ms
hash 1 done at 428 ms
hash 3 done at 428 ms
hash 4 done at 434 ms
hash 5 done at 843 ms
hash 6 done at 848 ms
```

One hash takes about 430 ms. Four take about the same time, because four threads did them side by side.
**Six take twice as long, in two waves**: four started together, and hashes 5 and 6 waited for a
thread to come free. Nothing about this is visible in the JavaScript. The calls returned at once,
and the waiting happened in a queue in front of the pool.

## Changing the size

`UV_THREADPOOL_SIZE` sets the pool's size when the process starts, from 1 up to 1024:

```
ana@dev:~/server/loop$ UV_THREADPOOL_SIZE=6 node pool.js 6
hash 4 done at 521 ms
hash 1 done at 543 ms
hash 3 done at 565 ms
hash 5 done at 597 ms
hash 2 done at 695 ms
hash 6 done at 696 ms
```

With six threads all six started at once, and none finished as early as 430 ms. **This computer has four
processors**, so six threads doing pure computation shared four processors and each one took
longer. Raising the pool helps when its threads mostly wait, such as on a slow disk or a slow DNS
server, and does little for work that needs a processor the whole time. It is also one pool for
the whole process: a burst of password hashes delays every file read queued behind it.

Lesson 9 is about setting variables like this one, and lesson 10 is about what to do with work that
needs more processors than a pool can give.
