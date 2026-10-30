---
title: Off the main thread
version: 1
---

**The fix is to open the database on another thread and send it the question.** The main thread
asks, carries on drawing, and handles the answer when it arrives. In Node that other thread is a
**worker**: a second JavaScript thread with its own event loop, which talks to the main one only by
messages. Each platform has its own name for the same arrangement, and they are below.

Save this as `query-worker.ts` in `~/planner/threads`. It opens its own connection, because a
`better-sqlite3` connection belongs to the thread that opened it, and answers each message with the
query's first row:

```typescript
// query-worker.ts: the database, opened in a thread of its own; it answers one message per query.
import Database from "better-sqlite3";
import { parentPort } from "node:worker_threads";

const db = new Database(":memory:");
parentPort!.on("message", (sql: string) => {
  parentPort!.postMessage(db.prepare(sql).get());
});
```

And the main thread's side, as `off-main.ts`. Everything is as in `blocking.ts` except that the
query is posted to the worker:

```typescript
// off-main.ts: the same slow query, sent to a worker thread while the main thread keeps drawing.
import { Worker } from "node:worker_threads";
import { slow } from "./slow.ts";

let frames = 0;
const screen = setInterval(() => frames++, 16);
const worker = new Worker(new URL("./query-worker.ts", import.meta.url));

setTimeout(() => {
  const before = frames;
  worker.postMessage(slow);
  worker.once("message", ({ rows }: { rows: number }) => {
    const drawn = frames - before;
    console.log(`worker: ${rows} rows; frames drawn while the query ran: ${drawn > 0 ? "at least one" : "none"}`);
    clearInterval(screen);
    worker.terminate();
  });
}, 100);
```

```
ana@dev:~/planner/threads$ node off-main.ts
worker: 3000000 rows; frames drawn while the query ran: at least one
```

The same three million rows, the same query, and **the screen kept drawing while it ran.** The query
took no less time; the main thread simply was not the one waiting for it. Node 22 runs the worker's
TypeScript the same way it runs the main file's, which is why the `new URL(…, import.meta.url)` can
name a `.ts` file.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l06-frames\" aria-label=\"Two timelines of frames due every 16 milliseconds. Above, the query runs on the main thread: while it runs, every frame that falls due is dropped, and drawing resumes only when it returns. Below, the query runs on a worker thread: the main thread draws every frame while the worker answers, and the answer arrives as a message.\"><defs><marker id=\"l06-frames-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the query on the main thread</text><text x=\"20\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main thread</text><rect x=\"140\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"164\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"188\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"212\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"236\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"260\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"284\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"308\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"332\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"356\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"380\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"404\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"428\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"452\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"476\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"500\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"524\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"548\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"572\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"596\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"620\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"644\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"668\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"692\" y=\"43\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"260\" y=\"74\" width=\"264\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"392.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">slow query</text><text x=\"392\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">frames dropped</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the query on a worker</text><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main thread</text><rect x=\"140\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"164\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"188\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"212\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"236\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"260\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"284\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"308\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"332\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"356\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"380\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"404\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"428\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"452\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"476\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"500\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"524\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"548\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"572\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"596\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"620\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"644\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"668\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"692\" y=\"173\" width=\"16\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker</text><rect x=\"260\" y=\"216\" width=\"264\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"392.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">slow query</text><path d=\"M524 216 L536 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-frames-ah-phosphor)\"></path><text x=\"540\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">the answer, as a message</text><text x=\"392\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">every frame drawn</text></svg>", "caption": "The query takes as long in both. What changes is which thread waits for it, and so whether the frames due in the meantime are drawn."}
```

## The same arrangement, three times

*These listings were not run for this course; they follow the Room, SwiftData and Expo SQLite
documentation.*

**Room** runs a `suspend` DAO function or a `Flow` on executors of its own, and refuses a query on
the main thread outright, so the arrangement is the default rather than a choice:

```kotlin
viewModelScope.launch {
    val week = dao.week("2026-10-19", "2026-10-26") // suspends; Room runs the query elsewhere
    _state.value = WeekState(week)                  // back on the main thread
}
```

**SwiftData** gives a background thread its own `ModelContext` through the `@ModelActor` macro. The
actor owns the context, and the main actor awaits its methods:

```swift
@ModelActor
actor SessionImporter {
    func save(_ rows: [SessionRow]) throws {
        for row in rows {
            modelContext.insert(Session(id: row.id, course: row.course, date: row.date, minutes: row.minutes))
        }
        try modelContext.save()
    }
}

let importer = SessionImporter(modelContainer: container)
try await importer.save(rows)
```

**`expo-sqlite`** has an asynchronous and a synchronous form of each call. The asynchronous one runs
on a native thread, leaving the JavaScript thread free; the synchronous one, `getAllSync`, is
`blocking.ts` again:

```typescript
const week = await db.getAllAsync(
  "SELECT * FROM sessions WHERE date >= ? AND date < ?",
  ["2026-10-19", "2026-10-26"],
);
```

## What it costs

A second thread is a second place the data can be read from, and two places can disagree. While the
worker writes a sync, the main thread may read a half-finished view unless both go through
transactions; lesson 3's WAL mode is what lets one read while the other writes. And the answer
arrives later than the question, so the screen has a moment where it has asked and not heard back.
Lesson 7 is about what to draw in that moment.
