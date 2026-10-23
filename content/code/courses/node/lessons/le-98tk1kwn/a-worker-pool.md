---
title: A pool of workers
version: 1
---

**Starting a worker for every request would cost a start-up each time and would start as many threads
as there are requests**, a thousand at once under load, all fighting for four processors. A **pool**
starts a fixed number once and keeps them; each job waits in a queue until one is free. This is the
same shape as libuv's pool of four threads in lesson 2, built in JavaScript:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A pool of four workers. Jobs arrive on the left and wait in a queue; each free worker takes the next job, and when it answers it is free again. A worker that throws is replaced by a new one.\"><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pool.run(job)</text><line x1=\"80\" y1=\"40\" x2=\"80\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"80.0,68.0 76.9,60.6 83.1,60.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"40\" y=\"70\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">queue</text><rect x=\"52\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"94\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"111\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"136\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"153\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"178\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><rect x=\"220\" y=\"84\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"237\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">job</text><line x1=\"270\" y1=\"100\" x2=\"360\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"360.0,100.0 352.6,103.1 352.6,96.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"315\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">next free</text><rect x=\"362\" y=\"20\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: busy</text><rect x=\"362\" y=\"64\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: busy</text><rect x=\"362\" y=\"108\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: busy</text><rect x=\"362\" y=\"152\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker: free</text><line x1=\"512\" y1=\"37\" x2=\"580\" y2=\"37\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"580.0,37.0 572.6,40.1 572.6,33.9\" fill=\"var(--phosphor)\"></polygon><text x=\"586\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">answer: resolve</text><line x1=\"512\" y1=\"81\" x2=\"580\" y2=\"81\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"580.0,81.0 572.6,84.1 572.6,77.9\" fill=\"var(--amber)\"></polygon><text x=\"586\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">throws: reject,</text><text x=\"586\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">and a new worker</text></svg>", "caption": "A fixed number of threads, started once; the queue is what absorbs the load."}
```

```schooling-example
{"language": "javascript", "file": "pool.js", "parts": [
 {"code": "// pool.js: a fixed number of workers, started once, and a queue of jobs for them.\nimport { Worker } from \"node:worker_threads\";\n\nexport class Pool {\n  #file;\n  #all = [];\n  #idle = [];\n  #queue = [];", "note": "**Three lists**: every worker, the ones free right now, and the jobs waiting. The `#` makes them private to the class."},
 {"code": "  constructor(file, size) {\n    this.#file = file;\n    for (let i = 0; i < size; i++) this.#start();\n  }\n\n  #start() {\n    const worker = new Worker(this.#file);\n    this.#all.push(worker);\n    this.#idle.push(worker);\n  }", "note": "All the workers are started at once, when the pool is made, and wait."},
 {"code": "  run(job) {\n    return new Promise((resolve, reject) => {\n      this.#queue.push({ job, resolve, reject });\n      this.#next();\n    });\n  }", "note": "**`run` queues the job and returns a promise** for its answer. The caller does not know or care which worker takes it."},
 {"code": "  #next() {\n    if (!this.#idle.length || !this.#queue.length) return;\n    const worker = this.#idle.pop();\n    const { job, resolve, reject } = this.#queue.shift();", "note": "**A job starts when there is both a free worker and a waiting job**; otherwise nothing happens until one of the two arrives."},
 {"code": "    const onMessage = (value) => {\n      worker.off(\"error\", onError);\n      this.#idle.push(worker);\n      resolve(value);\n      this.#next();\n    };", "note": "The answer: the worker goes back to the free list, and the next job, if there is one, starts on it."},
 {"code": "    const onError = (err) => {\n      worker.off(\"message\", onMessage);\n      this.#all = this.#all.filter((w) => w !== worker);\n      this.#start();\n      reject(err);\n      this.#next();\n    };", "note": "**An error thrown in a worker ends that worker**, so it is not put back: a new one is started in its place and the job's promise is rejected. Without this, a pool loses a worker on every failure until it has none."},
 {"code": "    worker.once(\"message\", onMessage);\n    worker.once(\"error\", onError);\n    worker.postMessage(job);\n  }\n\n  close() {\n    return Promise.all(this.#all.map((w) => w.terminate()));\n  }\n}", "note": "`close` ends every worker, so a program using the pool can exit."}
]}
```

The worker for a pool does not end after one answer. It listens, and answers every job it is sent;
this one also refuses a job too large to finish, which is how the failure path gets tested:

```javascript
// pool-worker.js: stays alive, and answers every job it is sent.
import { parentPort } from "node:worker_threads";
import { countPrimes } from "./primes.js";

parentPort.on("message", ({ from, to }) => {
  if (to > 100_000_000) throw new RangeError(`${to} is more than this worker will count to`);
  parentPort.postMessage(countPrimes(from, to));
});
```

Six jobs for a pool of two, the third of them refused:

```javascript
// jobs.js: six jobs for a pool of two, one of them refused.
import { Pool } from "./pool.js";

const pool = new Pool(new URL("./pool-worker.js", import.meta.url), 2);
const tos = [1e6, 2e6, 1e9, 3e6, 4e6, 5e6];
const results = await Promise.allSettled(tos.map((to) => pool.run({ from: 0, to })));
results.forEach((r, i) => console.log(`up to ${tos[i]}:`, r.status === "fulfilled" ? r.value : r.reason.message));
await pool.close();
```

```
ana@dev:~/server/procs$ node jobs.js
up to 1000000: 78498
up to 2000000: 148933
up to 1000000000: 1000000000 is more than this worker will count to
up to 3000000: 216816
up to 4000000: 283146
up to 5000000: 348513
```

**The refused job failed with its own message and the jobs after it still ran**, on the worker started
to replace the one that threw.

## A pool behind a server

The reason for all this is a server that stays responsive while it computes. `busy.js` has one slow
route and one fast one, and counts either on the main thread or in a pool of four:

```javascript
// busy.js: a server with a slow route, counted on the main thread or in a pool.
import http from "node:http";
import { availableParallelism } from "node:os";
import { Pool } from "./pool.js";
import { countPrimes } from "./primes.js";

const usePool = process.argv[2] === "pool";
const pool = usePool ? new Pool(new URL("./pool-worker.js", import.meta.url), availableParallelism()) : null;

http
  .createServer(async (req, res) => {
    if (req.url === "/primes") {
      const job = { from: 0, to: 5_000_000 };
      const count = usePool ? await pool.run(job) : countPrimes(job.from, job.to);
      return res.end(`${count} primes`);
    }
    res.end("ok");
  })
  .listen(3000, "127.0.0.1", () => console.log(`busy.js on :3000, ${usePool ? "with a pool" : "no pool"}`));
```

Four slow requests at once and, a moment later, a fast one. First with `node busy.js` running in the
other terminal, then with `node busy.js pool`:

```
ana@dev:~/server/procs$ for i in 1 2 3 4; do curl -s -o /dev/null -w 'primes %{time_total} s\n' http://127.0.0.1:3000/primes & done; sleep 0.2; curl -s -o /dev/null -w 'health %{time_total} s\n' http://127.0.0.1:3000/health; wait
primes 1.041229 s
primes 2.082061 s
primes 3.120471 s
primes 4.203286 s
health 4.002002 s
```

```
ana@dev:~/server/procs$ for i in 1 2 3 4; do curl -s -o /dev/null -w 'primes %{time_total} s\n' http://127.0.0.1:3000/primes & done; sleep 0.2; curl -s -o /dev/null -w 'health %{time_total} s\n' http://127.0.0.1:3000/health; wait
health 0.005477 s
primes 1.083871 s
primes 1.089210 s
primes 1.109622 s
primes 1.120725 s
```

**On the main thread, the four counts ran one after another and the fast request waited four seconds
behind them**: lesson 2's blocked loop, measured. **With the pool, the four ran at once, about a second
each, and the fast request was answered in milliseconds**, because the main thread was only passing
messages. A pool of four with a fifth slow request would queue it, which is the point: the queue is
in memory and cheap, and the processors are not oversubscribed.

For a real service, the package `piscina` is this pool with the parts left out here: cancelling a
job with an `AbortSignal`, a limit on how long the queue may grow, and a number of workers that grows
and shrinks with the load.
