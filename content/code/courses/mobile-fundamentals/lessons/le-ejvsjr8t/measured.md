---
title: The same sort, in the way of the frames and beside them
version: 1
---

**This section runs the rule instead of stating it: the same sort, once on the thread that keeps
the frames and once on a worker beside it, with the dropped frames counted.** The program is
Node.js, not a phone. Node runs JavaScript on one thread with an event loop, the shape the first
section of this lesson described, and its `worker_threads` module starts a second thread with a
loop of its own. A timer that fires every 16.67 ms plays the display. Nothing on the screen moves,
but the count of frames the timer missed is exactly what would have moved.

The work is the planner's: sort a month of study sessions by date and then by length, the order
the week view shows them in. Three hundred thousand is far more sessions than one student plans,
and that is deliberate. It stands in for the large JSON document and the long list of the
previous section, and it makes the cost large enough to measure on any computer.

## The program

Save this as `frames.ts` in `~/planner`, next to lesson 1's `planner.ts`, whose `Session` type it
imports:

```schooling-example
{"language": "typescript", "file": "frames.ts", "parts": [{"code": "// frames.ts: a 60 Hz frame clock, and a sort that runs in its way or beside it\nimport { Worker, isMainThread, parentPort } from \"node:worker_threads\";\nimport type { Session } from \"./planner.ts\";\n\nconst mode = process.argv[2] ?? \"idle\"; // idle, main or worker\nconst N = Number(process.argv[3] ?? 300000);\n", "note": "The program takes two arguments: where the sort runs, and how many sessions it sorts. `Session` is lesson 1's type, imported from `planner.ts`; `import type` disappears when `node` strips the types."}, {"code": "// N sessions from a fixed seed, so every run sorts the same data\nfunction makeSessions(n: number): Session[] {\n  let seed = 42;\n  const next = () => (seed = (seed * 16807) % 2147483647);\n  const out: Session[] = [];\n  for (let i = 0; i < n; i++) {\n    const day = String(1 + (next() % 28)).padStart(2, \"0\");\n    out.push({\n      id: \"s\" + i,\n      courseId: next() % 2 === 0 ? \"sql\" : \"mobile\",\n      date: `2026-10-${day}`,\n      minutes: 15 + (next() % 90),\n      done: false,\n    });\n  }\n  return out;\n}\n\n// By date, then by length; returns how long the sort took, in ms\nfunction sortSessions(list: Session[]): number {\n  const t0 = performance.now();\n  list.sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : a.minutes - b.minutes));\n  return performance.now() - t0;\n}\n", "note": "The data is a month of made-up sessions. The numbers come from a fixed seed rather than `Math.random`, so every run sorts the same list. The sort is the planner's week view in miniature, and `performance.now()` times it to a fraction of a millisecond."}, {"code": "if (!isMainThread) {\n  // In the worker: make the same data, say ready, sort on \"go\", send the time back\n  const list = makeSessions(N);\n  parentPort!.postMessage(\"ready\");\n  parentPort!.once(\"message\", () => parentPort!.postMessage(sortSessions(list)));\n}\n", "note": "This part runs only inside the worker. The same file is loaded a second time on another thread, where `isMainThread` is false. The worker makes its own copy of the data, so nothing large has to be copied across, and it sends back one number."}, {"code": "// The frame clock: one slot every 16.67 ms, counted from `start`\nconst period = 1000 / 60;\nlet start = 0, last = -1, drawn = 0, dropped = 0, longest = 0, prev = 0, running = true;\n\nfunction frame() {\n  const now = performance.now();\n  const k = Math.floor((now - start) / period); // the slot we are in\n  if (k > last) {\n    dropped += k - last - 1; // slots that passed with no frame\n    drawn += 1;\n    if (last >= 0) longest = Math.max(longest, now - prev);\n    last = k;\n    prev = now;\n  }\n  if (running) setTimeout(frame, start + (k + 1) * period - now);\n}\n", "note": "The clock stands in for the display. It asks to run at the start of each 16.67 ms slot, and when it runs it works out which slot it is in. Any slot it skipped is a dropped frame, the rule from the section on the budget: a frame that misses its slot is not drawn late, it is not drawn. `longest` keeps the widest gap between two frames."}, {"code": "// Start the clock, run the work 200 ms in, stop 200 ms after it ends, print\nfunction measure(work: (done: (sortMs?: number) => void) => void) {\n  start = prev = performance.now();\n  frame();\n  setTimeout(() => work((sortMs) => setTimeout(() => {\n    running = false;\n    console.log(`${mode}: ${N} sessions, a frame due every ${period.toFixed(2)} ms`);\n    if (sortMs !== undefined) console.log(`  sort took      ${sortMs.toFixed(0)} ms`);\n    console.log(`  frames drawn   ${drawn}`);\n    console.log(`  frames dropped ${dropped}`);\n    console.log(`  longest gap    ${longest.toFixed(1)} ms`);\n  }, 200)), 200);\n}\n", "note": "Every run has the same shape: 200 ms of quiet, the work, 200 ms of quiet, and then the counts."}, {"code": "if (isMainThread && mode === \"idle\") measure((done) => done());\n\nif (isMainThread && mode === \"main\") {\n  const list = makeSessions(N); // made before the clock starts\n  measure((done) => done(sortSessions(list)));\n}\n\nif (isMainThread && mode === \"worker\") {\n  const w = new Worker(new URL(import.meta.url), { argv: [mode, String(N)] });\n  w.once(\"message\", () =>\n    measure((done) => {\n      w.postMessage(\"go\");\n      w.once(\"message\", (ms: number) => {\n        done(ms);\n        w.terminate();\n      });\n    }),\n  );\n}", "note": "The three runs. `idle` does no work, so it shows what the clock does on its own. `main` sorts on the thread that runs the clock. `worker` starts a `Worker` from this same file, waits for it to be ready, says go, and keeps running the clock while the worker sorts."}]}
```

Run it three ways. `node frames.ts idle` runs the clock alone, `main` sorts on the clock's
thread, and `worker` sorts on a worker.

## Three runs

First the clock alone, with no work at all, to see what it does on a quiet machine:

```
ana@dev:~/planner$ node frames.ts idle
idle: 300000 sessions, a frame due every 16.67 ms
  frames drawn   24
  frames dropped 0
  longest gap    17.8 ms
```

**24 frames drawn and none dropped**: 400 ms of quiet is 24 slots of 16.67 ms. The longest gap
between two frames was 17.8 ms rather than exactly 16.67, because a timer fires when the event
loop gets to it and never exactly on time; that wobble stays inside one slot, so no frame is lost.

Now the sort on the same thread as the clock:

```
ana@dev:~/planner$ node frames.ts main
main: 300000 sessions, a frame due every 16.67 ms
  sort took      554 ms
  frames drawn   25
  frames dropped 33
  longest gap    570.4 ms
```

**The sort took 554 ms, and for all of it the clock could not run.** 33 frames were dropped, and
the longest gap between two frames was 570.4 ms: more than half a second in which a real app
would have drawn nothing and answered no touch. By Android's names that is one very slow frame,
short of the 700 ms that would make it a frozen one, and a scroll begun in that half-second would
have waited for all of it.

The same sort, on a worker:

```
ana@dev:~/planner$ node frames.ts worker
worker: 300000 sessions, a frame due every 16.67 ms
  sort took      470 ms
  frames drawn   53
  frames dropped 0
  longest gap    21.9 ms
```

**No frame dropped.** The clock drew 53 frames, one in every slot, and its longest gap was
21.9 ms, still inside the next slot. The sort took 470 ms on the worker, which is not faster in
any way that matters: the work is the same, and it was done. It was done on another thread,
which is the whole difference.

## What the numbers are, and what they are not

**They are one run on one machine**, with four processor cores, captured once for this lesson.
Run it yourself and every number except the first line will differ, from run to run and from
machine to machine; the sort can take twice as long on a slower laptop, or less on a faster one.
What does not change is the shape: a few hundred milliseconds of sorting on the clock's thread
costs a few dozen frames, and the same sort on a worker costs none.

**And Node.js is a model of a phone, not a phone.** A phone's main thread also lays out and
draws, the system decides how much processor time the app gets, and a phone that is hot or low
on battery runs slower. Two things carry over exactly, and they are why the model is worth
running: the clock of a single-threaded loop cannot tick while a function is still running, and
work moved to another thread leaves that loop free. The worker in `frames.ts` makes its own copy
of the data and sends back one number. A real app has to send back the sorted list itself, and
copying a large result between two threads takes time on both of them, so that copy is worth
measuring too rather than assuming it is free.
