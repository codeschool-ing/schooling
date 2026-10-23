---
title: Worker threads
version: 1
---

**A worker thread is a second JavaScript thread inside the same process**, with an event loop and a
heap of its own. It starts faster than a process and takes less memory, and it runs on another
processor at the same time as the main thread. Lesson 2 said JavaScript in Node runs on one thread;
that is true of each thread, and `node:worker_threads` is how a program gets more than one.

```schooling-example
{"language": "javascript", "file": "worker.js", "parts": [
 {"code": "// worker.js: runs on a thread of its own, with workerData as its input.\nimport { parentPort, workerData } from \"node:worker_threads\";\nimport { countPrimes } from \"./primes.js\";", "note": "**`workerData` is the input given when the worker was created**, and `parentPort` is the channel back to the thread that created it."},
 {"code": "parentPort.postMessage(countPrimes(workerData.from, workerData.to));", "note": "One answer, and then nothing is left for this thread's loop, so it ends on its own."}
]}
```

```schooling-example
{"language": "javascript", "file": "threads.js", "parts": [
 {"code": "// threads.js: the same count, on one thread and then split across several.\nimport { Worker } from \"node:worker_threads\";\nimport { availableParallelism } from \"node:os\";\nimport { countPrimes } from \"./primes.js\";\n\nconst N = 10_000_000;", "note": "`availableParallelism()` is how many processors this program may use at once: the right number of workers for work that only computes."},
 {"code": "function inWorker(from, to) {\n  return new Promise((resolve, reject) => {\n    const worker = new Worker(new URL(\"./worker.js\", import.meta.url), { workerData: { from, to } });\n    worker.once(\"message\", resolve);\n    worker.once(\"error\", reject);\n  });\n}", "note": "**A worker wrapped in a promise**: its first message resolves it and an error thrown inside it rejects it. The file is given as a URL beside this module, so it is found wherever the program is started from."},
 {"code": "let started = performance.now();\nconsole.log(`main thread: ${countPrimes(0, N)} primes in ${Math.round(performance.now() - started)} ms`);", "note": "The whole count on the main thread, for comparison."},
 {"code": "const threads = availableParallelism();\nconst step = N / threads;\nstarted = performance.now();\nconst parts = await Promise.all(Array.from({ length: threads }, (_, i) => inWorker(i * step, (i + 1) * step)));\nconst total = parts.reduce((a, b) => a + b, 0);\nconsole.log(`${threads} workers: ${total} primes in ${Math.round(performance.now() - started)} ms`, parts);", "note": "**The same range in equal slices, one per worker, all at once.** `Promise.all` waits for every slice."}
]}
```

```
ana@dev:~/server/procs$ node threads.js
main thread: 664579 primes in 2763 ms
4 workers: 664579 primes in 959 ms [ 183072, 165441, 159748, 156318 ]
```

**The same answer, about three times as fast on four processors.** Not four times: the slices are equal
in length and not in work, since a larger number takes longer to test, so the last slice is the one
everyone waits for, and starting four workers costs something too. That gap between the processors
you have and the speed-up you get is normal, and it is why a measurement is worth more than a
multiplication.

**A worker is for computing, not for waiting.** Reading a file, querying a database or calling an API
already happen off the main thread, in the system or in libuv's pool from lesson 2. Putting them in a
worker adds a thread that waits where the main one would have waited, and saves nothing.
