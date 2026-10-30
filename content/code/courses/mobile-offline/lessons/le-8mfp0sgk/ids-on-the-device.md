---
title: Ids made on the device
version: 1
---

**A row created offline needs an id before the server has seen it, so the device has to make one
that no other device can make.** `INTEGER PRIMARY KEY AUTOINCREMENT` is what most people reach for,
and it is the one choice that cannot work: a counter is unique on one database, and a person with a
phone and a tablet has two.

The program below gives two devices the same six sessions, the state after their last sync, and
then each adds one more while offline, the phone a Statistics session and the tablet a Guitar one.
Once with ids from a counter, once with UUIDs. Save it as `ids.ts` in `~/planner/model`:

```typescript
// ids.ts: two devices each add a session while offline, with ids from a counter and with UUIDs.
import Database from "better-sqlite3";
import { randomUUID } from "node:crypto";

type Kind = "counter" | "uuid";

// A device's sessions table, and its function for adding one: it returns the id the row got.
function device(kind: Kind): (course: string) => string {
  const db = new Database(":memory:");
  if (kind === "counter") {
    db.exec("CREATE TABLE sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, course TEXT NOT NULL)");
    const add = db.prepare("INSERT INTO sessions (course) VALUES (?)");
    return (course) => String(add.run(course).lastInsertRowid);
  }
  db.exec("CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL)");
  const add = db.prepare("INSERT INTO sessions (id, course) VALUES (?, ?)");
  return (course) => {
    const id = randomUUID();
    add.run(id, course);
    return id;
  };
}

for (const kind of ["counter", "uuid"] as Kind[]) {
  const phone = device(kind);
  const tablet = device(kind);
  for (let n = 0; n < 6; n++) { phone("spanish"); tablet("spanish"); } // the six both already had
  const a = phone("statistics"); // offline, on the phone
  const b = tablet("guitar"); // offline, on the tablet, the same evening
  const detail = kind === "counter" ? `phone ${a}, tablet ${b}` : `${a.length} characters each`;
  console.log(`${kind.padEnd(7)}: statistics and guitar get ${a === b ? "the same id" : "different ids"} (${detail})`);
}
```

```
ana@dev:~/planner/model$ node ids.ts
counter: statistics and guitar get the same id (phone 7, tablet 7)
uuid   : statistics and guitar get different ids (36 characters each)
```

**Both devices called their new session 7.** When they sync, the server receives two different
sessions under one id, and whichever arrives second either overwrites the first or is refused.
Either way a session the person typed is gone or stuck, and nothing on either screen says so. With
UUIDs the two ids differ, and the server can store both. The program prints the length rather than
the ids, because `randomUUID` makes a new one every run and the transcript has to repeat; yours
will be a different 36 characters.

## What a UUID is, and which kind

`crypto.randomUUID()` returns a version 4 UUID: 122 random bits written as 36 characters. The chance
of two devices making the same one is small enough that no planner will ever see it. Every
platform has the same call: `UUID.randomUUID()` in Kotlin, `UUID()` in Swift, and
`Crypto.randomUUID()` from `expo-crypto` in React Native.

Random ids have one cost on a device: consecutive rows land in random places in the primary-key
index, so inserts touch more pages than they would with an ever-growing key. **Version 7**, defined
in RFC 9562 in 2024, puts a millisecond timestamp in the first 48 bits and randomness in the rest,
so ids made one after another sort one after another. Node 22 has no built-in for it; libraries do,
and the choice between the two is a measurement for a large table, not a rule.

## And the server's own ids

Some APIs insist on making the id themselves. The device then keeps two: its own, made offline and
used for every local reference, and the server's, stored beside it once the first sync answers.
Lesson 8's outbox has to carry the local id for exactly this reason, so that the answer can be
matched to the row that asked.
