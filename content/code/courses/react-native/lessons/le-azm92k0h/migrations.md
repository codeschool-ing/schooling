---
title: A second version of the schema
version: 1
---

**A phone keeps its database across every update of the app**, so the schema of the version the person
installed a year ago is still there when today's version opens. Changing the schema is never editing the
`CREATE TABLE`: a phone that already has the table would never run it again. It is adding a migration.

The journal's totals group by course, and as the table grows SQLite would read every row to do it. An
index on the course is the second version. In `src/journal.ts`, add one line to the end of `MIGRATIONS`:

```ts
// src/journal.ts: a log, kept on this phone, of every session marked done here, and what it adds up to.
// It asks for three methods and no more, so a test can hand it any SQLite that has them.
export interface Sql {
  execAsync(source: string): Promise<void>;
  runAsync(source: string, ...params: (string | number)[]): Promise<unknown>;
  getAllAsync<T>(source: string, ...params: (string | number)[]): Promise<T[]>;
}

// Each entry moves the database one version on. Entries are only ever added at the end.
const MIGRATIONS = [
  "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL)",
  "CREATE INDEX done_by_course ON done (course)",
];

export async function migrate(db: Sql) {
  const [{ user_version: from }] = await db.getAllAsync<{ user_version: number }>("PRAGMA user_version");
  for (let v = from; v < MIGRATIONS.length; v++) {
    await db.execAsync(`BEGIN; ${MIGRATIONS[v]}; PRAGMA user_version = ${v + 1}; COMMIT;`);
  }
}

export type Done = { id: string; course: string; minutes: number };

export async function record(db: Sql, s: Done, at: string) {
  await db.runAsync(
    "INSERT OR IGNORE INTO done (session, course, minutes, done_at) VALUES (?, ?, ?, ?)",
    s.id, s.course, s.minutes, at,
  );
}

export function totals(db: Sql) {
  return db.getAllAsync<{ course: string; minutes: number }>(
    "SELECT course, sum(minutes) AS minutes FROM done GROUP BY course ORDER BY course",
  );
}
```

**Entries are only ever added at the end.** Version 1 is whatever the first entry did on every phone that
ran it; changing it now would change nothing on those phones and something else on new ones, and the two
would disagree in silence.

The test that matters is the one for a phone already at version 1, with rows in it. In
`__tests__/journal.test.ts`, the first test now expects version 2, and a fourth builds a version-1
database by hand, as it was, and migrates it:

```ts
// __tests__/journal.test.ts: the journal's SQL, run by Node's own SQLite in memory.
import { migrate, record, totals } from "../src/journal";
import { openTestDatabase } from "../test-sqlite";

const guitar = { id: "s3", course: "guitar", minutes: 20 };
const spanish = { id: "s4", course: "spanish", minutes: 30 };

test("an empty database is brought to the latest version", async () => {
  const db = openTestDatabase();
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 2 }]);
  expect(await totals(db)).toEqual([]);
});

test("totals are per course, and a session logged twice counts once", async () => {
  const db = openTestDatabase();
  await migrate(db);
  await record(db, guitar, "2026-10-21T18:00:00Z");
  await record(db, spanish, "2026-10-22T18:00:00Z");
  await record(db, guitar, "2026-10-21T18:05:00Z"); // a retry: same session
  expect(await totals(db)).toEqual([
    { course: "guitar", minutes: 20 },
    { course: "spanish", minutes: 30 },
  ]);
});

test("migrating twice changes nothing", async () => {
  const db = openTestDatabase();
  await migrate(db);
  await record(db, guitar, "2026-10-21T18:00:00Z");
  await migrate(db);
  expect(await totals(db)).toEqual([{ course: "guitar", minutes: 20 }]);
});

test("a database left at version 1 moves to version 2 and keeps its rows", async () => {
  const db = openTestDatabase();
  // how version 1 left a phone: the table, one row, and the version number
  await db.execAsync(
    "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL);" +
      "PRAGMA user_version = 1;",
  );
  await record(db, guitar, "2026-10-21T18:00:00Z");
  await migrate(db);
  expect(await db.getAllAsync("PRAGMA user_version")).toEqual([{ user_version: 2 }]);
  expect(await db.getAllAsync("SELECT name FROM sqlite_master WHERE name = 'done_by_course'")).toHaveLength(1);
  expect(await totals(db)).toEqual([{ course: "guitar", minutes: 20 }]);
});
```

```
ana@dev:~/planner$ npx jest journal --verbose --forceExit
(node:19) ExperimentalWarning: SQLite is an experimental feature and might change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
PASS __tests__/journal.test.ts
  ✓ an empty database is brought to the latest version (5 ms)
  ✓ totals are per course, and a session logged twice counts once (1 ms)
  ✓ migrating twice changes nothing (1 ms)
  ✓ a database left at version 1 moves to version 2 and keeps its rows (2 ms)

Test Suites: 1 passed, 1 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        0.725 s, estimated 1 s
Ran all test suites matching journal.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**The row survived the upgrade, and the index is there.** That test is the one to write for every
migration, because "a new phone works" is what every developer checks by accident, and "a phone from last
year works" is what nobody checks until a review says the app lost somebody's data.
