---
title: A version number in the file, and a list of steps
version: 1
---

**A server's database is migrated once, by somebody watching; a phone's is migrated a million
times, by the app, on devices nobody can log into.** The update arrives from the store while the
person sleeps, the app opens in the morning, and before the first screen it has to turn whatever
database it finds into the one this version expects. Nobody is there to look at an error, and the
database holds data that exists nowhere else.

So the migration has to be boring: a number in the file that says what shape it is in, and an
ordered list of steps that each move it one version on. SQLite keeps the number for you.
`PRAGMA user_version` is an integer in the file's header, 0 in a new file, which SQLite never
changes on its own. Room, Core Data and Realm keep a version of their own the same way, and
`expo-sqlite`'s documentation suggests exactly this pragma for React Native.

Make the lesson's folder, `~/planner/migrate`, and save this as `migrations.ts`:

```typescript
// migrations.ts: the planner's schema as an ordered list of steps, and the function that applies them.
import type { Database } from "better-sqlite3";

// steps[0] takes an empty file to version 1, steps[1] takes version 1 to 2, and so on.
// A step that has shipped is never edited again: a phone may still be about to run it.
export const steps: string[] = [
  `CREATE TABLE courses (id TEXT PRIMARY KEY, name TEXT NOT NULL);
   CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL REFERENCES courses (id),
                          date TEXT NOT NULL, minutes INTEGER NOT NULL, done INTEGER NOT NULL DEFAULT 0);`,
  `ALTER TABLE sessions ADD COLUMN notes TEXT NOT NULL DEFAULT '';`,
  `ALTER TABLE sessions ADD COLUMN synced INTEGER NOT NULL DEFAULT 1;`,
  `ALTER TABLE sessions ADD COLUMN done_at TEXT;
   UPDATE sessions SET done_at = date WHERE done = 1;
   ALTER TABLE sessions DROP COLUMN done;
   CREATE INDEX sessions_unsent ON sessions (id) WHERE synced = 0;`,
];

export function version(db: Database): number {
  return db.pragma("user_version", { simple: true }) as number;
}

// Run every step after the file's version, in order, in one transaction with the new version number.
export function migrate(db: Database, to = steps.length): void {
  const from = version(db);
  db.transaction(() => {
    for (let v = from; v < to; v++) db.exec(steps[v]);
    db.pragma(`user_version = ${to}`);
  })();
}
```

The planner's history is four steps. Version 1 is lesson 3's two tables. Version 2 gave sessions a
note. Version 3 added `synced`, which lesson 4 used to decide what may be pruned; rows that existed
before it were all on the server already, so they default to 1. Version 4 replaced `done`, a yes or
no, with `done_at`, the day it was done, copying the old answers across before dropping the old
column, and added an index on the rows still waiting to be sent.

Three rules are written into that file, and each one is there because breaking it loses data:

- **The steps run in order, from the file's version to the last.** Never "the latest schema", always
  the path to it.
- **A shipped step is never edited.** If version 3 was wrong, version 5 fixes it. Some phone is still
  at version 2 and will run version 3 exactly as it shipped.
- **The steps and the new number commit together**, in one transaction. The next section but one
  shows what happens when they do not.

`version` and `migrate` are all the app calls at launch: open the file, `migrate(db)`, then draw. On
a fresh install the file is empty, its version is 0, and the same function builds it from
step 1, so a new install and an old phone end in the same place by the same code. The next
section checks that claim rather than trusting it.
