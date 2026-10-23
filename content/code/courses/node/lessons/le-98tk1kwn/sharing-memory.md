---
title: Copied, transferred or shared
version: 1
---

**Two threads of one process still do not see each other's objects.** A message between them is
copied, with the *structured clone* algorithm, which copies more types than JSON does (a `Map`, a
`Date`, a typed array) and copies them all the same. There are two ways round the copy, for bytes only:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three ways data reaches a worker. Copied: the main thread keeps its data and the worker gets a separate copy. Transferred: the bytes move to the worker and the main thread is left with an empty buffer. Shared: one block of memory that both threads read and write at the same time.\"><text x=\"20\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">copied</text><text x=\"20\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">postMessage(x)</text><rect x=\"200\" y=\"30\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">main</text><rect x=\"420\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"284\" y=\"38\" width=\"28\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"494\" y=\"38\" width=\"28\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"320\" y1=\"50\" x2=\"418\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,50.0 410.6,53.1 410.6,46.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"545\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both have it, twice</text><text x=\"20\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">transferred</text><text x=\"20\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">postMessage(x, [x.buffer])</text><rect x=\"200\" y=\"100\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">main</text><rect x=\"420\" y=\"100\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"284\" y=\"108\" width=\"28\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"494\" y=\"108\" width=\"28\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"320\" y1=\"120\" x2=\"418\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,120.0 410.6,123.1 410.6,116.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"545\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the worker has it; ours is empty</text><text x=\"20\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shared</text><text x=\"20\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SharedArrayBuffer</text><rect x=\"200\" y=\"170\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">main</text><rect x=\"420\" y=\"170\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"332\" y=\"176\" width=\"76\" height=\"28\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">one block</text><line x1=\"320\" y1=\"190\" x2=\"332\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><line x1=\"408\" y1=\"190\" x2=\"420\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"545\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both at once: use Atomics</text></svg>", "caption": "A copy costs time, a transfer costs the sender its copy, and sharing costs care."}
```

The first two, in one program:

```schooling-example
{"language": "javascript", "file": "copy.js", "parts": [
 {"code": "// copy.js: what postMessage does to the data it is given.\nimport { Worker } from \"node:worker_threads\";\n\nconst worker = new Worker(\n  `const { parentPort } = require(\"node:worker_threads\");\n   parentPort.on(\"message\", (m) => { m.list.push(\"added by the worker\"); parentPort.postMessage(m.list.length); });`,\n  { eval: true },\n);", "note": "**A worker's code can be a string**, with `eval: true`, which keeps a demonstration in one file. Code given that way is CommonJS, which is why it uses `require`."},
 {"code": "const list = [\"one\", \"two\"];\nworker.postMessage({ list });\nconsole.log(\"the worker's copy has\", await new Promise((r) => worker.once(\"message\", r)), \"items\");\nconsole.log(\"ours still has\", list.length);", "note": "**Copied**: the worker pushed onto its own copy of the list, and ours did not change."},
 {"code": "const bytes = new Uint8Array(64 * 2 ** 20);\nlet t = performance.now();\nworker.postMessage({ list: [], bytes });\nawait new Promise((r) => worker.once(\"message\", r));\nconsole.log(`64 MB copied in ${Math.round(performance.now() - t)} ms; ours is ${bytes.byteLength} bytes`);", "note": "Sixty-four megabytes, copied the same way."},
 {"code": "t = performance.now();\nworker.postMessage({ list: [], bytes }, [bytes.buffer]);\nawait new Promise((r) => worker.once(\"message\", r));\nconsole.log(`64 MB transferred in ${Math.round(performance.now() - t)} ms; ours is ${bytes.byteLength} bytes`);\nawait worker.terminate();", "note": "**Transferred**: the second argument lists buffers to hand over rather than copy. The bytes move to the worker, and our view of them is left empty."}
]}
```

```
ana@dev:~/server/procs$ node copy.js
the worker's copy has 3 items
ours still has 2
64 MB copied in 74 ms; ours is 67108864 bytes
64 MB transferred in 2 ms; ours is 0 bytes
```

**A copy of 64 MB cost tens of milliseconds; a transfer cost almost nothing**, because no byte moved,
only the right to use them. The price is that the sender loses them, and `byteLength` 0 is what it
holds afterwards.

## Shared, and Atomics

**A `SharedArrayBuffer` is memory both threads use at once**: sending it sends access to the same
bytes, not a copy. That is the fastest way for threads to cooperate and the one way to get the bugs
threads are known for, which this program has on purpose:

```schooling-example
{"language": "javascript", "file": "counter.js", "parts": [
 {"code": "// counter.js: four threads adding to one shared number, with and without Atomics.\nimport { Worker } from \"node:worker_threads\";"},
 {"code": "const code = `\n  const { workerData } = require(\"node:worker_threads\");\n  const n = new Int32Array(workerData.shared);\n  for (let i = 0; i < 1_000_000; i++) {\n    if (workerData.atomic) Atomics.add(n, 0, 1);\n    else n[0]++;\n  }`;", "note": "**Each worker adds one, a million times, to the same number.** `n[0]++` reads the number, adds one and writes it back, in three steps another thread can come between."},
 {"code": "for (const atomic of [false, true]) {\n  const shared = new SharedArrayBuffer(4);\n  const workers = Array.from({ length: 4 }, () => new Worker(code, { eval: true, workerData: { shared, atomic } }));\n  await Promise.all(workers.map((w) => new Promise((r) => w.once(\"exit\", r))));\n  console.log(`${atomic ? \"Atomics.add\" : \"n[0]++     \"}: ${new Int32Array(shared)[0]} of 4000000`);\n}", "note": "**Four bytes, shared by four workers**, once with plain increments and once with `Atomics.add`, which does the three steps as one."}
]}
```

```
ana@dev:~/server/procs$ node counter.js
n[0]++     : 3242706 of 4000000
Atomics.add: 4000000 of 4000000
```

**`n[0]++` lost increments, and a different number of them on every run**: two threads read the same
value, both add one, both write it back, and one of the two additions is gone. `Atomics.add` cannot
be interrupted halfway, so it counted every one. A lost update like this does not crash and does not
repeat the same way twice, which is what makes it expensive to find.

**The usual answer is not to share.** Send a worker its input, let it answer with a message, and keep
`SharedArrayBuffer` for the rare case where copying is measured to be too slow.
