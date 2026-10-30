---
title: The outbox, written with the change
version: 1
---

**An outbox is a table of operations the server has not seen yet, and each one is written in the
same transaction as the change it describes.** Lesson 7 kept one fact per row, `pending` or
`synced`. That says *that* a row needs sending and nothing about *what* to send: a session that was
created, then lengthened, then deleted is one row in that design, and the server needs to hear all
three things, or at least the last.

The wrong picture is that the outbox is a list of requests the app made while offline and will
replay later. It is not a list of requests. It is a list of **changes to the planner's data**, in
the order they happened, kept next to the data so the two can never disagree.

## Why the same transaction

Write the session and then, separately, the outbox row, and there is a moment between the two. If
the app is killed in that moment, by the system reclaiming memory or by the battery, the session is
on the device and nothing will ever send it. **No error is raised, and the row looks exactly like
one that was sent.** Written in one transaction, the two land together or neither does.

## The planner's outbox

This lesson's folder is `~/planner/outbox`. Three tables: the sessions, the outbox, and a third,
`dead`, which the last section of the lesson needs. Each change is a function wrapped in
`db.transaction`, which `better-sqlite3` turns into `BEGIN` and `COMMIT` around it, or `ROLLBACK`
if it throws. Save this as `store.ts`:

```typescript
// store.ts: the planner's sessions, and the outbox of operations the server has not seen yet.
import Database from "better-sqlite3";

export const db = new Database("planner.db");
db.exec(`
create table if not exists sessions (
  id text primary key, course text not null, date text not null, minutes integer not null);
create table if not exists outbox (
  seq     integer primary key autoincrement,
  op      text not null check (op in ('create', 'update', 'delete')),
  session text not null,
  body    text);
create table if not exists dead (
  seq integer primary key, op text not null, session text not null, body text, reason text not null);
`);

const enqueue = db.prepare("insert into outbox (op, session, body) values (?, ?, ?)");
const row = db.prepare("select id, course, date, minutes from sessions where id = ?");

// Each change and its outbox row are written together, or not at all.
export const addSession = db.transaction((id: string, course: string, date: string, minutes: number) => {
  db.prepare("insert into sessions values (?, ?, ?, ?)").run(id, course, date, minutes);
  enqueue.run("create", id, JSON.stringify(row.get(id)));
});
export const setMinutes = db.transaction((id: string, minutes: number) => {
  db.prepare("update sessions set minutes = ? where id = ?").run(minutes, id);
  enqueue.run("update", id, JSON.stringify(row.get(id)));
});
export const removeSession = db.transaction((id: string) => {
  db.prepare("delete from sessions where id = ?").run(id);
  enqueue.run("delete", id, null);
});
```

`seq` is the order. `AUTOINCREMENT` makes SQLite hand out a number higher than any it has used in
this table, even one since deleted, so an operation added later can never sort before one added
earlier. The body is the whole row as it stood after the change, not the change itself; the next
section says why that is the easier thing to send.

The commands, standing in for the planner's screens. `revive` is for the last section; skip it
for now. Save this as `app.ts`:

```typescript
// app.ts: the planner's commands for this lesson: change sessions, and look at the outbox.
import { db, addSession, setMinutes, removeSession } from "./store.ts";

const [command, ...a] = process.argv.slice(2);
if (command === "add") addSession(a[0], a[1], a[2], Number(a[3]));
if (command === "minutes") setMinutes(a[0], Number(a[1]));
if (command === "remove") removeSession(a[0]);
if (command === "revive") {
  // The person fixed a session the server refused: send it again as it is now.
  db.transaction(() => {
    const dead = db.prepare("select op from dead where session = ? order by seq").get(a[0]) as { op: string };
    db.prepare("delete from dead where session = ?").run(a[0]);
    db.prepare("delete from outbox where session = ?").run(a[0]);
    const now = db.prepare("select * from sessions where id = ?").get(a[0]);
    db.prepare("insert into outbox (op, session, body) values (?, ?, ?)").run(dead.op === "create" ? "create" : "update", a[0], JSON.stringify(now));
  })();
}
if (command === "outbox") {
  for (const o of db.prepare("select seq, op, session, body from outbox order by seq").all() as any[]) {
    console.log(`#${o.seq} ${o.op.padEnd(6)} ${o.session}  ${o.body ?? ""}`.trimEnd());
  }
  for (const d of db.prepare("select seq, op, session, reason from dead order by seq").all() as any[]) {
    console.log(`dead #${d.seq} ${d.op} ${d.session}: ${d.reason}`);
  }
}
```

Add a session, lengthen it, add a second one, and look at what is waiting:

```
ana@dev:~/planner/outbox$ node app.ts add s7 guitar 2026-10-23 25
ana@dev:~/planner/outbox$ node app.ts minutes s7 30
ana@dev:~/planner/outbox$ node app.ts add s8 statistics 2026-10-24 40
ana@dev:~/planner/outbox$ node app.ts outbox
#1 create s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}
#2 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":30}
#3 create s8  {"id":"s8","course":"statistics","date":"2026-10-24","minutes":40}
```

Three changes, three operations, in order. Nothing has been sent, because nothing in these
commands knows a server exists.
