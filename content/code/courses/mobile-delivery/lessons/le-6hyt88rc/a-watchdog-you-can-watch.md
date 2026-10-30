---
title: A watchdog you can watch
version: 1
---

**A hang can be noticed only from outside the thread that is hung.** The hang detectors in Sentry,
Crashlytics and the Android libraries that report ANRs all work the same way: the main thread
updates a **heartbeat**, a timestamp, several times a second, and a second thread checks it. When the
heartbeat stops changing for longer than a limit, the second thread records what it can, while the
main thread is still stuck.

Node has a main thread too, and worker threads beside it, so the same arrangement runs here. Save
this as `hang.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "hang.ts", "parts": [{"code": "// hang.ts: a main thread that stops answering, and a watchdog thread that notices\nimport { Worker, isMainThread, workerData } from \"node:worker_threads\";\nimport { writeFileSync, writeSync } from \"node:fs\";\n\nconst LIMIT_MS = 5000;", "note": "One file runs as both threads: `isMainThread` says which one it is. The limit is Android's five seconds for an input event."}, {"code": "if (isMainThread) {\n  const beat = new Int32Array(new SharedArrayBuffer(8));\n  const started = Date.now();\n  const tick = () => Atomics.store(beat, 0, Date.now() - started);\n  const watchdog = new Worker(new URL(import.meta.url), { workerData: { beat, started } });\n  setInterval(tick, 100).unref();\n  tick();", "note": "The heartbeat is a number in memory both threads share. The main thread rewrites it every 100 ms, but only when it is free to run a timer."}, {"code": "  const mode = process.argv[2] ?? \"blocking\";\n  console.log(`open the week (${mode})`);\n  setTimeout(async () => {\n    if (mode === \"blocking\") {\n      const until = Date.now() + 6000;\n      while (Date.now() < until) {} // stands in for parsing a year of sessions on the main thread\n    } else {\n      await new Promise((done) => setTimeout(done, 6000)); // the same wait, with the main thread free\n    }\n    console.log(`week ready after ${Math.round((Date.now() - started) / 1000)} s`);\n    watchdog.terminate();\n  }, 200);", "note": "Six seconds of work, done two ways: a loop that holds the main thread, or a wait that leaves it free."}, {"code": "} else {\n  const { beat, started } = workerData as { beat: Int32Array; started: number };\n  let reported = false;\n  setInterval(() => {\n    const silent = Date.now() - started - Atomics.load(beat, 0);\n    if (silent >= LIMIT_MS && !reported) {\n      reported = true;\n      writeFileSync(\"hang-report.txt\", `main thread silent for ${silent} ms\\n`);\n      writeSync(1, `watchdog: main thread silent for ${Math.floor(silent / 1000)} s, hang report written\\n`);\n    }\n  }, 250);\n}", "note": "The watchdog thread reads the heartbeat four times a second. Past the limit it writes a report, and prints straight to the terminal, without asking the main thread."}]}
```

Run it the blocking way, then the other way:

```
ana@dev:~/planner$ node hang.ts blocking
open the week (blocking)
watchdog: main thread silent for 5 s, hang report written
week ready after 6 s
ana@dev:~/planner$ node hang.ts free
open the week (free)
week ready after 6 s
ana@dev:~/planner$ cat hang-report.txt
main thread silent for 5108 ms
```

## What the transcript shows

**In the blocking run, the watchdog's line appears before the week is ready**, while the main thread
is still stuck in its loop. That is the whole point of a second thread: the main one could not have
reported anything until it was free, and by then, on a phone, the system might have killed it.

The watchdog writes its line with `writeSync` straight to the terminal, not with `console.log`, and
that detail is the lesson in miniature. In a worker, `console.log` hands the text to the main thread
to print, and the main thread is the one that is stuck; the message would arrive after the freeze it
describes. **A hang detector cannot ask the hung thread for help with anything.**

In the second run, the same six seconds are spent waiting on a timer, which stands in for work done
on another thread, and the heartbeat never stops. No report: the app was slow, and it never froze.

## The limit is a choice

The script reports at 5 seconds, Android's limit for an input event. Real detectors report sooner,
often at 2 seconds, because a freeze of two seconds is already one a person notices, and an ANR
report at five arrives only for the freezes that lasted long enough for the system to count. Sentry
calls the shorter ones **app hangs**, and reports them separately from ANRs.
