---
title: A query that stops the screen
version: 1
---

**`better-sqlite3` is synchronous: while a query runs, nothing else in the program runs.** That is a
deliberate design, and on a server or in a script it is the fastest way to use SQLite. It also makes
Node a fair model of a phone's main thread, because Node runs your JavaScript on one thread with an
event loop, and a timer that is due cannot fire while a call is still running.

So the experiment needs a screen and a slow query. The screen is a timer that counts a frame every
16 ms, as a 60 Hz display would. The query has to be slow on any computer, including a fast one, so
rather than depending on a large file it asks SQLite to count to three million. It stands in for the
query that is slow on somebody's phone: a search over every note, the history of a course three years
long. Make the lesson's folder, `~/planner/threads`, and save the query on its own as `slow.ts`:

```typescript
// slow.ts: a query made slow on purpose, so it is slow on any computer: it counts to three million.
export const slow =
  "WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 3000000) SELECT count(*) AS rows FROM n";
```

Then the program that runs it on the main thread, as `blocking.ts`:

```typescript
// blocking.ts: a slow query on the main thread, and the frames that were due while it ran.
import Database from "better-sqlite3";
import { slow } from "./slow.ts";

let frames = 0;
const screen = setInterval(() => frames++, 16); // one frame every 16 ms, as at 60 Hz

setTimeout(() => {
  const before = frames;
  const db = new Database(":memory:");
  const { rows } = db.prepare(slow).get() as { rows: number };
  const drawn = frames - before;
  console.log(`main thread: ${rows} rows; frames drawn while the query ran: ${drawn > 0 ? "at least one" : "none"}`);
  clearInterval(screen);
}, 100);
```

It waits 100 ms so the screen is already drawing, notes the frame count, runs the query, and counts
again. The program prints whether any frame was drawn in between, and not how many or how long the
query took, because both depend on the computer and the transcript has to be the same on yours:

```
ana@dev:~/planner/threads$ node blocking.ts
main thread: 3000000 rows; frames drawn while the query ran: none
```

**None.** However long the query took on your computer, the timer did not fire once until it
returned. On a phone that is a frozen screen: the list does not scroll, a button does not press, the
spinner you put up to say "loading" does not spin, because it is drawn by the same thread.

Notice what did not help. The query is correct, the database is in memory, and nothing waited for a
disk. Blocking is about where the work runs, not about how efficient it is; an efficient query on
the main thread is still a query on the main thread.

The next section keeps everything identical and moves the query to another thread.
