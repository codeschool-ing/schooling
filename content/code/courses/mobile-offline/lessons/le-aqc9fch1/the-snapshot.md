---
title: The snapshot, and the swap that cannot be seen halfway
version: 1
---

**A full resync downloads the server's whole live data into a new file beside the old one, and then
replaces the old file with the new one in a single rename.** Until the rename, the app is still
reading the old copy, complete and consistent; after it, the new one. There is no moment in which a
screen can read half of each.

The obvious version deletes every row and inserts the snapshot's, inside the live database. It is
correct when nothing goes wrong. If the app is killed halfway, the person opens a planner with half
their sessions, and the next screen they see is a lie. A transaction would save the rows, but a
download takes seconds on a slow network, and holding a write transaction open across the network
blocks every other write the app makes, including the person's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l12-swap\" aria-label=\"Three steps of a resync. First, the screens read planner.db, the old copy, while planner.db.next is written beside it with the server's snapshot and then the pending outbox rows, applied again. Second, both files are closed. Third, one rename makes planner.db.next the new planner.db, and the screens read the new copy. At no moment is a file read half written.\"><defs><marker id=\"l12-swap-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">1 · written beside the old copy</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.db</text><text x=\"120.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the screens read it</text><rect x=\"20\" y=\"104\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.db.next</text><text x=\"120.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the server's snapshot</text><text x=\"120.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+ the outbox, applied again</text><text x=\"300\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">2 · one rename</text><path d=\"M220 136 L300 136 L300 62 L496 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-swap-ah-amber)\"></path><text x=\"350\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">rename</text><text x=\"500\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">3 · the new copy</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.db</text><text x=\"600.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the screens read it</text></svg>", "caption": "Until the rename the app reads the old copy, whole; after it, the new one. Nothing ever reads a file that is half written."}
```

## The device, in three files

The device's tables, now opened from more than one place, go in a file of their own. Save this as
`store.ts`:

```typescript
// store.ts: open a planner database file, with the three tables every device copy has.
import Database from "better-sqlite3";

export function open(file: string) {
  const db = new Database(file);
  db.exec(`
    create table if not exists sessions (id text primary key, course text, date text, minutes integer);
    create table if not exists outbox (seq integer primary key autoincrement, op text, session text, body text);
    create table if not exists meta (name text primary key, value text);`);
  return db;
}
```

The resync itself. Read it beside the notes:

```schooling-example
{"language": "typescript", "file": "resync.ts", "parts": [{"code": "// resync.ts: replace the device's copy with the server's snapshot, keeping what is not sent yet.\nimport { renameSync, rmSync } from \"node:fs\";\nimport { open } from \"./store.ts\";\n", "note": "The whole of the device's side of a resync, in one function, so that `device.ts` can call it the moment the server answers 410."}, {"code": "export async function resync(server: string, file: string) {\n  const text = await (await fetch(`${server}/snapshot`)).text();\n  const snapshot = JSON.parse(text) as { cursor: number; sessions: Record<string, unknown>[] };\n", "note": "One request for everything the server has, with the cursor that goes with it. It is the only part that needs the network, and it happens before anything on the device changes."}, {"code": "  rmSync(`${file}.next`, { force: true });\n  const next = open(`${file}.next`);\n  const old = open(file);\n  next.transaction(() => {", "note": "A second file beside the first. A leftover from a resync that crashed is removed first; the old file is opened only to be read."}, {"code": "    const save = next.prepare(\"insert or replace into sessions values (@id, @course, @date, @minutes)\");\n    for (const s of snapshot.sessions) save.run(s);\n    next.prepare(\"insert into meta values ('cursor', ?)\").run(String(snapshot.cursor));\n", "note": "The snapshot goes into the new file, with its cursor."}, {"code": "    const pending = old.prepare(\"select seq, op, session, body from outbox order by seq\").all() as\n      { seq: number; op: string; session: string; body: string | null }[];\n    for (const o of pending) {\n      next.prepare(\"insert into outbox values (?, ?, ?, ?)\").run(o.seq, o.op, o.session, o.body);\n      if (o.op === \"delete\") next.prepare(\"delete from sessions where id = ?\").run(o.session);\n      else save.run(JSON.parse(o.body!));\n    }\n    console.log(`snapshot: ${snapshot.sessions.length} sessions, ${text.length} bytes; ${pending.length} pending carried over`);\n  })();", "note": "Then the outbox is copied across, and each pending operation is applied again to the new copy, so the person's unsent work is still on the screen and still waiting to be sent."}, {"code": "  old.close();\n  next.close();\n", "note": "Both connections closed, so nothing is half written to either file."}, {"code": "  renameSync(`${file}.next`, file);\n}", "note": "The swap. A rename within one folder is atomic: whoever opens `planner.db` afterwards gets the old file or the new one, never a mixture."}]}
```

And the commands: `add` writes a session and its outbox row together, as lesson 8 does; `pull` asks
for a delta and calls `resync` when the answer is 410; `show` prints the sessions, marking those
still waiting to be sent. Save this as `device.ts`:

```typescript
// device.ts: the planner's copy on this device: add a session, pull changes, show what is there.
import { open } from "./store.ts";
import { resync } from "./resync.ts";

const SERVER = "http://127.0.0.1:8012";
const FILE = "planner.db";
const [command, ...a] = process.argv.slice(2);
const db = open(FILE);
const cursor = () => Number((db.prepare("select value from meta where name = 'cursor'").get() as { value: string } | undefined)?.value ?? 0);

if (command === "add") {
  const body = { id: a[0], course: a[1], date: a[2], minutes: Number(a[3]) };
  db.transaction(() => {
    db.prepare("insert into sessions values (@id, @course, @date, @minutes)").run(body);
    db.prepare("insert into outbox (op, session, body) values ('create', ?, ?)").run(a[0], JSON.stringify(body));
  })();
}
if (command === "pull") {
  const res = await fetch(`${SERVER}/changes?after=${cursor()}`);
  if (res.status === 410) {
    console.log(`410: ${(await res.json()).error}`);
    db.close();
    await resync(SERVER, FILE);
  } else {
    const { cursor: next, changes } = await res.json();
    db.transaction(() => {
      for (const c of changes) c.deleted ? db.prepare("delete from sessions where id = ?").run(c.id)
        : db.prepare("insert or replace into sessions values (@id, @course, @date, @minutes)").run(c);
      db.prepare("insert or replace into meta values ('cursor', ?)").run(String(next));
    })();
    console.log(`delta: ${changes.length} changes, cursor ${next}`);
  }
}
if (command === "show") {
  const now = open(FILE);
  const waiting = new Set((now.prepare("select session from outbox").all() as { session: string }[]).map((o) => o.session));
  for (const s of now.prepare("select * from sessions order by date, id").all() as { id: string; course: string; date: string; minutes: number }[]) {
    console.log(`${s.id.padEnd(4)} ${s.date}  ${s.course.padEnd(10)} ${String(s.minutes).padStart(3)} min${waiting.has(s.id) ? "  waiting to send" : ""}`);
  }
  console.log(`cursor ${(now.prepare("select value from meta where name = 'cursor'").get() as { value: string }).value}`);
}
```

Restart the server, pull, and repeat the previous section's story: the delete on another phone, the
server forgetting, and the pull that comes back to a 410. This time the device answers it:

```
ana@dev:~/planner/resync$ node device.ts pull
delta: 6 changes, cursor 6
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -o /dev/null -X POST http://127.0.0.1:8012/forget
ana@dev:~/planner/resync$ node device.ts pull
410: cursor 6 is older than 7; resync
snapshot: 5 sessions, 453 bytes; 0 pending carried over
ana@dev:~/planner/resync$ node device.ts show
s1   2026-10-19  spanish     30 min
s2   2026-10-20  statistics  45 min
s4   2026-10-22  spanish     30 min
s5   2026-10-26  statistics  60 min
s6   2026-10-28  guitar      20 min
cursor 7
ana@dev:~/planner/resync$ ls
device.ts
planner.db
resync.ts
server.ts
store.ts
```

Five sessions, `s3` gone, cursor 7: the device now matches the server exactly, from a pull that
began with a refusal. `ls` shows one database file. The `.next` file existed for the length of the
resync and became `planner.db` in the rename; the old file's name was simply given to it.

## One detail about SQLite

The rename is safe here because `better-sqlite3`, like SQLite by default, keeps a database in one
file, and both connections are closed before the swap. A database in WAL mode keeps recent writes
in a second file, `planner.db-wal`, and renaming the main file alone would leave those behind or,
worse, apply them to the wrong file. An app in WAL mode checkpoints and closes the database before
it swaps, and Room, Core Data and SwiftData each document how to close their store so the file can
be replaced.
