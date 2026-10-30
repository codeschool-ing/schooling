---
title: The local write, and the screen that reads the database
version: 1
---

**In an offline-first app, every change goes to the database on the device, and every screen is
drawn from that database.** No screen reads the network directly, and that is the rule that makes
the app behave the same with or without a connection. A screen that fetched "just this one list"
from the server would be the one screen that breaks in a tunnel.

The planner's version is two files in a folder of their own, `~/planner/offline`. The first holds
the database. Every session row carries a `sync` column, which the next section is about;
for now, notice that a new row is `pending` by default. Save this as `store.ts`:

```typescript
// store.ts: the planner's sessions on the device, each one with its sync state.
import Database from "better-sqlite3";

export type Sync = "pending" | "synced" | "failed";
export type Row = { id: string; course: string; date: string; minutes: number; sync: Sync; error: string | null };

export const db = new Database("planner.db");
db.exec(`create table if not exists sessions (
  id      text primary key,
  course  text not null,
  date    text not null,
  minutes integer not null,
  done    integer not null default 0,
  sync    text not null default 'pending' check (sync in ('pending', 'synced', 'failed')),
  error   text
)`);

// The only way the app changes a session: write it here, marked as not sent yet.
export function addSession(id: string, course: string, date: string, minutes: number) {
  db.prepare("insert into sessions (id, course, date, minutes) values (?, ?, ?, ?)").run(id, course, date, minutes);
}

export function week(monday: string): Row[] {
  return db.prepare(`select id, course, date, minutes, sync, error from sessions
    where date >= ? and date < date(?, '+7 days') order by date, id`).all(monday, monday) as Row[];
}

export function pending(): Row[] {
  return db.prepare("select id, course, date, minutes, sync, error from sessions where sync = 'pending' order by id").all() as Row[];
}

export function settle(id: string, sync: Sync, error: string | null = null) {
  db.prepare("update sessions set sync = ?, error = ? where id = ?").run(sync, error, id);
}
```

The second is the app's commands, standing in for its screens. `seed` loads lesson 1's six
sessions as rows the server already has; `add` is the person typing a session; `week` is the
week's screen, read from the database. Only `sync` would talk to a server, and until lesson 8 the
server is a function in the same file. Save this as `app.ts`:

```typescript
// app.ts: the planner's commands. Every screen reads the database; only `sync` talks to a server.
import { addSession, week, pending, settle, type Row } from "./store.ts";
import { sessions } from "../data.ts";

const label: Record<Row["sync"], string> = { pending: "waiting to send", synced: "saved", failed: "not saved:" };

// A stand-in for the server, until lesson 8 writes a real one. It refuses what a real one would.
function server(row: Row): string | null {
  if (row.minutes > 240) return "a session is at most 240 minutes";
  return null;
}

const [command, ...args] = process.argv.slice(2);
if (command === "seed") {
  // What the server already had: lesson 1's sessions, all of them saved.
  for (const s of sessions) {
    addSession(s.id, s.course, s.date, s.minutes);
    settle(s.id, "synced");
  }
  console.log(`seeded ${sessions.length} sessions`);
} else if (command === "add") {
  const [id, course, date, minutes] = args;
  addSession(id, course, date, Number(minutes));
  console.log(`added ${id}`);
} else if (command === "week") {
  for (const r of week(args[0])) {
    console.log(`${r.date}  ${r.course.padEnd(10)} ${String(r.minutes).padStart(3)} min  ${label[r.sync]} ${r.error ?? ""}`.trimEnd());
  }
} else if (command === "sync") {
  const online = args[0] === "online";
  for (const r of pending()) {
    if (!online) { console.log(`${r.id}: no network, still pending`); continue; }
    const refused = server(r);
    settle(r.id, refused ? "failed" : "synced", refused);
    console.log(`${r.id}: ${refused ? "refused, " + refused : "accepted"}`);
  }
}
```

Seed it, add a session, and draw the week. There is no network anywhere in these three commands:

```
ana@dev:~/planner/offline$ node app.ts seed
seeded 6 sessions
ana@dev:~/planner/offline$ node app.ts add s7 guitar 2026-10-23 25
added s7
ana@dev:~/planner/offline$ node app.ts week 2026-10-19
2026-10-19  spanish     30 min  saved
2026-10-20  statistics  45 min  saved
2026-10-21  guitar      20 min  saved
2026-10-22  spanish     30 min  saved
2026-10-23  guitar      25 min  waiting to send
```

The new session is on the screen at once, as `waiting to send`. Nothing was sent, nothing waited
for an answer, and the screen told the truth about both.

## The same rule on the three platforms

Each platform has a way for a screen to **observe** the database, so that a write anywhere in the
app redraws every screen that shows that row. *These listings were not run for this course; they
follow the documentation of Room, SwiftData and Expo's `expo-sqlite`.*

```kotlin
// Room: the DAO returns a Flow, and the screen collects it.
@Query("SELECT * FROM sessions WHERE date >= :monday AND date < :sunday ORDER BY date")
fun week(monday: String, sunday: String): Flow<List<SessionEntity>>
```

```swift
// SwiftData: the view declares the query, and SwiftUI redraws it when the store changes.
@Query(sort: \Session.date) private var sessions: [Session]
```

```typescript
// expo-sqlite: the hook re-runs the query when the table changes.
const sessions = useLiveQuery(db.select().from(sessionsTable).orderBy(sessionsTable.date));
```

The Expo line uses Drizzle's `useLiveQuery` on top of `expo-sqlite`, which is one common way; the
library's own change listener is another. In all three, the screen never asks "did the save work?".
It draws what is in the database, and the save is what put it there.
