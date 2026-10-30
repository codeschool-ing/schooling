---
title: A database for the planner's data
version: 1
---

**The planner's courses and sessions are the student's work, they grow every week, and the screens
ask questions of them: this week's total, one course's sessions, what is not done yet.** That is a
database's job. And on a phone there is one already there: **SQLite**, which ships inside both
Android and iOS. It is not a server. It is a library that keeps a whole database in one ordinary file
in the app's sandbox, which is exactly the shape a phone wants.

Each platform puts its own layer over it, and the courses after the fork teach them: **Room** on
Android, **SwiftData** on iOS, which may keep its data in SQLite underneath, and on React Native a
library such as `expo-sqlite`. They add types, migrations and a way to watch a query for changes.
Under Room and `expo-sqlite`, the file is SQLite.

On your computer, SQLite comes through `better-sqlite3`, a Node.js library that carries its own copy
of it. Install it in `~/planner`; the `-E` records the exact version in `package.json`:

```
ana@dev:~/planner$ npm install -E better-sqlite3@13.0.3

added 2 packages in 2s
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "type": "module",
  "dependencies": {
    "better-sqlite3": "13.0.3"
  }
}
```

## The planner in SQLite

`store.ts` creates `planner.db` with two tables, puts lesson 1's week into them, and asks SQL for the
same total `weekTotal` computed in TypeScript. Save it as `store.ts`:

```schooling-example
{"language": "typescript", "file": "store.ts", "parts": [{"code": "// store.ts: the planner's courses and sessions in SQLite, and the week's total in SQL\nimport Database from \"better-sqlite3\";\nimport { mondayOf } from \"./planner.ts\";\n\nconst db = new Database(\"planner.db\");\ndb.pragma(\"foreign_keys = ON\");\n", "note": "Opening `planner.db` creates the file if it is not there. SQLite enforces a session's `REFERENCES courses` only when foreign keys are switched on, which is one `pragma` per connection."}, {"code": "db.exec(`\n  CREATE TABLE IF NOT EXISTS courses (\n    id    TEXT PRIMARY KEY,\n    title TEXT NOT NULL\n  );\n  CREATE TABLE IF NOT EXISTS sessions (\n    id        TEXT PRIMARY KEY,\n    course_id TEXT NOT NULL REFERENCES courses (id),\n    date      TEXT NOT NULL,\n    minutes   INTEGER NOT NULL,\n    done      INTEGER NOT NULL\n  );\n`);\n", "note": "The two lists of lesson 1's `Plan`, as two tables. A session still points at its course by id, and now the database refuses one that points at nothing, as `addSession` did. SQLite has no boolean, so `done` is 0 or 1."}, {"code": "const addCourse = db.prepare(\"INSERT OR IGNORE INTO courses (id, title) VALUES (?, ?)\");\nconst addSession = db.prepare(\n  \"INSERT OR IGNORE INTO sessions (id, course_id, date, minutes, done) VALUES (?, ?, ?, ?, ?)\",\n);\ndb.transaction(() => {\n  addCourse.run(\"sql\", \"SQL Databases\");\n  addCourse.run(\"mobile\", \"Mobile Fundamentals\");\n  addSession.run(\"s1\", \"sql\", \"2026-10-19\", 50, 1);\n  addSession.run(\"s2\", \"mobile\", \"2026-10-20\", 40, 1);\n  addSession.run(\"s3\", \"sql\", \"2026-10-23\", 60, 0);\n  addSession.run(\"s4\", \"mobile\", \"2026-10-27\", 45, 0);\n  addSession.run(\"s5\", \"mobile\", \"2026-10-22\", 30, 1);\n})();\n", "note": "Lesson 1's week, with `s5` already done. The `?` are filled by `run`, never pasted into the SQL. The transaction writes all seven rows or none, and `OR IGNORE` leaves a row alone if its id is already there, so a second run adds nothing."}, {"code": "const monday = mondayOf(process.argv[2]); // \"today\" is given, as in week.ts\nconst totals = db\n  .prepare(\n    `SELECT sum(minutes) AS planned,\n            sum(CASE WHEN done THEN minutes ELSE 0 END) AS done\n       FROM sessions\n      WHERE date >= ? AND date < date(?, '+7 days')`,\n  )\n  .get(monday, monday);\nconsole.log({ monday, ...totals });\ndb.close();", "note": "`weekTotal` from lesson 1, as one query. Dates written `YYYY-MM-DD` sort as text in date order, so the week is every date from Monday up to, not including, the Monday after."}]}
```

Run it for the week of 21 October, and look at the file it made:

```
ana@dev:~/planner$ node store.ts 2026-10-21
{ monday: '2026-10-19', planned: 180, done: 120 }
ana@dev:~/planner$ ls -l planner.db
-rw-r--r-- 1 ana ana 20480 Oct 30 03:27 planner.db
```

**The same two numbers as lesson 1, 180 planned and 120 done**, now computed by the database rather
than by a loop over an array. The difference matters once the plan is a year long: the query reads
the sessions of one week, and an index on `date` would let it find them without reading the rest.

`planner.db` is one file of 20,480 bytes, five pages of 4,096: one for SQLite's own catalogue of
tables, and two for each table, one for its rows and one for the index its text `PRIMARY KEY` makes. It holds the schema and the data, and it
is the file the backup takes. **Running `store.ts` a second time changes nothing**, because `INSERT OR
IGNORE` leaves a row alone when its id is already there. The total is the same, and the folder now
holds everything this lesson's programs keep, the stand-in for the planner's sandbox:

```
ana@dev:~/planner$ node store.ts 2026-10-21
{ monday: '2026-10-19', planned: 180, done: 120 }
ana@dev:~/planner$ ls -l
total 48
drwxr-xr-x 4 ana ana  4096 Oct 30 03:27 node_modules
-rw-r--r-- 1 ana ana   986 Oct 30 03:27 package-lock.json
-rw-r--r-- 1 ana ana   119 Oct 30 03:27 package.json
-rw-r--r-- 1 ana ana 20480 Oct 30 03:27 planner.db
-rw-r--r-- 1 ana ana  1451 Oct 30 03:27 planner.ts
-rw-r--r-- 1 ana ana    33 Oct 30 03:27 prefs.json
-rw-r--r-- 1 ana ana   867 Oct 30 03:27 prefs.ts
-rw-r--r-- 1 ana ana  1541 Oct 30 03:27 store.ts
```

## What the file does not do for you

**A database file on a phone outlives every version of the app that wrote it.** The day the planner
adds a `notes` column, the phones in the world still hold the old table, and the new version must
change it in place, on a device nobody can log into, without losing a row. That is a *migration*, and
it is a subject of its own: the `mobile-offline` course teaches it in its lesson 5, after its lesson 3
compares SQLite, Room, SwiftData and Realm.

**And the database is the slowest thing the main thread can wait for.** `better-sqlite3` answers
synchronously, which is fine for a script that runs once. In an app, a query on the main thread
holds the frame for as long as it takes, which is the jank of lesson 6; the platform libraries run
queries on another thread, and `mobile-offline` lesson 6 is about the list that stutters when they do
not.
