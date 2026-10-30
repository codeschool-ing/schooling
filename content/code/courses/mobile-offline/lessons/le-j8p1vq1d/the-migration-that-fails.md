---
title: The migration that fails, and what it leaves
version: 1
---

**A migration will one day fail on somebody's phone, and the only thing you control is the state it
leaves behind.** A full disk, a row nobody expected, a statement SQLite refuses: none of it shows up
on a test device with three rows. What matters is whether the person's data is still intact and
whether the next version of the app can still migrate it.

Version 5 below renames the notes column and then adds a reminder column that SQLite refuses, a
`NOT NULL` column with no default on a table that already has rows. The program runs it twice per
mode, as two launches of the app, once statement by statement and once in a transaction. Save it
as `broken.ts` in `~/planner/migrate`:

```typescript
// broken.ts: a fifth step that fails halfway, run without a transaction and inside one.
import Database from "better-sqlite3";
import { migrate, version } from "./migrations.ts";

// Step 5 renames a column, then adds one that SQLite refuses on a table that has rows.
const step5 = [
  "ALTER TABLE sessions RENAME COLUMN notes TO note",
  "ALTER TABLE sessions ADD COLUMN reminder TEXT NOT NULL",
];
const columns = (db: Database.Database) =>
  (db.prepare("SELECT name FROM pragma_table_info('sessions')").all() as { name: string }[]).map((c) => c.name).join(", ");

for (const mode of ["statement by statement", "in a transaction"]) {
  const db = new Database(":memory:");
  migrate(db);
  db.prepare("INSERT INTO courses VALUES ('statistics', 'Statistics')").run();
  db.prepare("INSERT INTO sessions (id, course, date, minutes) VALUES ('s5', 'statistics', '2026-10-26', 60)").run();
  const run = () => { for (const sql of step5) db.exec(sql); db.pragma("user_version = 5"); };
  for (const launch of [1, 2]) {
    try {
      if (mode === "in a transaction") db.transaction(run)(); else run();
    } catch (e) {
      console.log(`${mode}, launch ${launch}: ${(e as Error).message}`);
    }
    console.log(`  version ${version(db)}; columns: ${columns(db)}`);
  }
}
```

```
ana@dev:~/planner/migrate$ node broken.ts
statement by statement, launch 1: Cannot add a NOT NULL column with default value NULL
  version 4; columns: id, course, date, minutes, note, synced, done_at
statement by statement, launch 2: no such column: "notes"
  version 4; columns: id, course, date, minutes, note, synced, done_at
in a transaction, launch 1: Cannot add a NOT NULL column with default value NULL
  version 4; columns: id, course, date, minutes, notes, synced, done_at
in a transaction, launch 2: Cannot add a NOT NULL column with default value NULL
  version 4; columns: id, course, date, minutes, notes, synced, done_at
```

**Statement by statement, the first launch renamed `notes` to `note` and then failed, and the file
still says version 4.** The database is now a shape no version of the app knows: version 4 code
looks for `notes`, which is gone. On the second launch the rename itself fails, because there is no
`notes` left to rename, so even a corrected step 5 shipped tomorrow would fail on this phone.
Nothing can migrate it without special code for a state that should never have existed.

In a transaction, the failure rolled the rename back with everything else. Both launches fail,
which the person sees as an app that will not open, but the file is exactly version 4, every column
where version 4 left it, and a fixed step 5 in the next release migrates it normally. **A failed
migration that changes nothing is a bug; one that changes half is data loss.**

SQLite is unusual in that `ALTER TABLE`, `CREATE` and `DROP` take part in a transaction like any
other statement. Room runs each migration inside a transaction for you, which is one reason to let
it.

## What the app does when it fails

The failure still has to go somewhere. Three things are worth doing, and one is worth refusing.

- **Report it.** A crash reporter, or a log the next successful launch uploads, with the from and to
  versions. A migration failing on 0.1% of phones is invisible from the store's reviews.
- **Keep the old file.** Copy the database before migrating, with lesson 3's three WAL files or
  SQLite's backup API, and delete the copy once the migration commits.
- **Tell the person something true**, such as "the planner could not update its data; it is safe,
  and an update will fix this", rather than a blank screen.
- **Do not delete the database to make the error go away.** That is the next section's subject.
