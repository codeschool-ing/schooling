---
title: SQLite on your computer, and the planner's first tables
version: 1
---

**An SQLite database is one ordinary file, and nothing else.** No server to start, no port, no
password. The app opens the file and reads it, the way a phone app opens `databases/planner.db` or
`Library/Application Support/planner.db`. That is why it suits a device: the database goes where the
sandbox puts it, and lesson 1's backup rules apply to it like to any other file.

Two tools reach it in this course. **`better-sqlite3`**, which lesson 1 installed, is how the
planner's programs use it. **The `sqlite3` shell** lets you look at the same file by hand, and it
comes from your system's packages:

```sh
sudo apt install sqlite3
```

On a Mac it is already there. The shell's version and the library's may differ; the file format
is the same, and either can open a file the other wrote.

## The two tables

Make the lesson's folder, `~/planner/db`, and save this in it as `load.ts`. It creates the tables
and copies lesson 1's data into them:

```typescript
// load.ts: create the planner's database and put lesson 1's data in it.
import Database from "better-sqlite3";
import { courses, sessions } from "../data.ts";

const db = new Database("planner.db");
db.exec(`
  CREATE TABLE IF NOT EXISTS courses (
    id   TEXT PRIMARY KEY,
    name TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS sessions (
    id      TEXT PRIMARY KEY,
    course  TEXT NOT NULL REFERENCES courses (id),
    date    TEXT NOT NULL,
    minutes INTEGER NOT NULL CHECK (minutes > 0),
    done    INTEGER NOT NULL DEFAULT 0
  );
`);

const addCourse = db.prepare("INSERT OR REPLACE INTO courses (id, name) VALUES (?, ?)");
const addSession = db.prepare(
  "INSERT OR REPLACE INTO sessions (id, course, date, minutes, done) VALUES (?, ?, ?, ?, ?)",
);
for (const c of courses) addCourse.run(c.id, c.name);
for (const s of sessions) addSession.run(s.id, s.course, s.date, s.minutes, s.done ? 1 : 0);

const count = db.prepare("SELECT count(*) AS n FROM sessions").get() as { n: number };
console.log(`planner.db: ${courses.length} courses, ${count.n} sessions`);
```

The schema says what the planner believes about its data, and SQLite enforces it. A session
cannot name a course that does not exist, because of `REFERENCES`; it cannot last zero minutes,
because of the `CHECK`. The first of those needs foreign keys switched on, which `better-sqlite3`
does for every connection and SQLite itself does not: the `sqlite3` shell starts with them off,
until `PRAGMA foreign_keys = ON`. `done` is an `INTEGER`, 0 or 1, because
SQLite has no boolean type. `INSERT OR REPLACE` makes the program safe to run twice.

```
ana@dev:~/planner/db$ node load.ts
planner.db: 3 courses, 6 sessions
```

Now the same file, through the shell. `.tables` lists the tables; `-header -column` lays rows out
as a table:

```
ana@dev:~/planner/db$ sqlite3 planner.db .tables
courses   sessions
ana@dev:~/planner/db$ sqlite3 -header -column planner.db "SELECT * FROM sessions"
id  course      date        minutes  done
--  ----------  ----------  -------  ----
s1  spanish     2026-10-19  30       1   
s2  statistics  2026-10-20  45       1   
s3  guitar      2026-10-21  20       0   
s4  spanish     2026-10-22  30       0   
s5  statistics  2026-10-26  60       0   
s6  guitar      2026-10-28  20       0   
```

## The week, asked of the database

Lesson 1's `show.ts` computed the week by filtering an array. Here the database does the filtering
and the adding, and returns only the answer. Save this as `week.ts`:

```typescript
// week.ts: the week screen, asked of the database instead of computed in memory.
import Database from "better-sqlite3";

const monday = process.argv[2] ?? "2026-10-19";
const db = new Database("planner.db", { readonly: true });
const week = db.prepare(`
  SELECT c.name, count(*) AS sessions, sum(s.minutes) AS planned,
         sum(CASE WHEN s.done THEN s.minutes ELSE 0 END) AS done
  FROM sessions s JOIN courses c ON c.id = s.course
  WHERE s.date >= ? AND s.date < date(?, '+7 days')
  GROUP BY c.id ORDER BY c.name
`);
for (const row of week.all(monday, monday)) console.log(row);
```

`date(?, '+7 days')` is SQLite's own date arithmetic, applied to the same text dates lesson 1
chose; it works because `YYYY-MM-DD` sorts as text in the same order as the days it names.

```
ana@dev:~/planner/db$ node week.ts 2026-10-19
{ name: 'Guitar', sessions: 1, planned: 20, done: 0 }
{ name: 'Spanish A2', sessions: 2, planned: 60, done: 30 }
{ name: 'Statistics', sessions: 1, planned: 45, done: 45 }
```

**The numbers are lesson 1's**: 125 minutes planned in the week of 19 October, 75 of them done,
spread over three courses. The difference is where they were computed. With six sessions it makes
none; the next section makes it twenty thousand.
