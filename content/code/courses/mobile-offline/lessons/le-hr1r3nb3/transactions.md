---
title: Transactions, and the batch that half arrived
version: 1
---

**A transaction makes several writes one: all of them reach the database, or none do.** Without
one, each statement commits on its own, and a batch that fails in the middle leaves the first half
in place. On a device that batch is usually a download from the server, the subject of lesson 11,
and half of one is a planner that is wrong in a way nobody chose.

## A batch with one bad row

The program below adds 1,000 sessions twice, into a database held in memory. Session 501 lasts
zero minutes, which the `CHECK` refuses. The first time each insert stands alone; the second time
they run inside `db.transaction`, which `better-sqlite3` turns into `BEGIN`, the inserts, and
`COMMIT`, or `ROLLBACK` if anything throws. Save it as `batch.ts` in `~/planner/db`:

```typescript
// batch.ts: add 1,000 sessions in one go, where session 501 is wrong, with and without a transaction.
import Database from "better-sqlite3";

const db = new Database(":memory:");
db.exec(`CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL, date TEXT NOT NULL,
                                minutes INTEGER NOT NULL CHECK (minutes > 0), done INTEGER NOT NULL)`);
const add = db.prepare("INSERT INTO sessions VALUES (?, 'statistics', '2026-10-20', ?, 0)");
const batch = Array.from({ length: 1000 }, (_, i) => ({ id: `b${i + 1}`, minutes: i === 500 ? 0 : 30 }));
const count = () => (db.prepare("SELECT count(*) AS n FROM sessions").get() as { n: number }).n;

try {
  for (const s of batch) add.run(s.id, s.minutes); // each insert commits on its own
} catch (e) {
  console.log(`one at a time: ${(e as Error).message}; ${count()} rows stayed`);
}

db.exec("DELETE FROM sessions");
const all = db.transaction((rows: typeof batch) => {
  for (const s of rows) add.run(s.id, s.minutes);
});
try {
  all(batch); // one transaction: every insert, or none
} catch (e) {
  console.log(`in a transaction: ${(e as Error).message}; ${count()} rows stayed`);
}
```

```
ana@dev:~/planner/db$ node batch.ts
one at a time: CHECK constraint failed: minutes > 0; 500 rows stayed
in a transaction: CHECK constraint failed: minutes > 0; 0 rows stayed
```

**Five hundred rows stayed the first time.** The screen would show them, the person would see half
a download, and the program would have to work out which half. In the transaction, the failure
rolled everything back, and the database is exactly as it was before the batch started: the
download can be tried again from the start.

The same transaction is also why the batch is fast, though this course quotes no timing. Each
commit waits for the disk to confirm the write, so a thousand commits wait a thousand times and one
commit waits once. `big.ts` puts its 20,000 inserts inside one transaction for that reason.

## Write-ahead logging

By default SQLite writes a change into the database file and keeps the old pages in a separate
journal, so it can undo. **Write-ahead logging** turns that around: changes go to a `-wal` file
first, and are copied into the database later. Readers keep reading the database while a write is
in progress, which on a phone means the screen can query while a sync writes. Save this as
`wal.ts`:

```typescript
// wal.ts: switch planner.db to write-ahead logging, and see what it adds beside the file.
import Database from "better-sqlite3";
import { readdirSync } from "node:fs";

const db = new Database("planner.db");
console.log("before:", db.pragma("journal_mode", { simple: true }));
console.log("after: ", db.pragma("journal_mode = WAL", { simple: true }));
db.prepare("UPDATE sessions SET done = 1 WHERE id = 's3'").run();
console.log(readdirSync(".").filter((f) => f.startsWith("planner.db")));
db.close();
console.log(readdirSync(".").filter((f) => f.startsWith("planner.db")));
```

```
ana@dev:~/planner/db$ node wal.ts
before: delete
after:  wal
[ 'planner.db', 'planner.db-shm', 'planner.db-wal' ]
[ 'planner.db' ]
```

`journal_mode` was `delete`, the default, and is now `wal`, and the setting is stored in the file,
so it stays. While the database is open, two files sit beside it: the log and `-shm`, an index of
the log in shared memory. When the last connection closes, SQLite copies the log back and removes
both.

**Those two files are part of the database.** Copying `planner.db` alone while the app has it open
copies a database without its latest writes. Room switches WAL on by default and Core Data's
SQLite stores use it too; a backup tool, or an export, has to take the three files together, or
ask SQLite for a copy with its backup API.
