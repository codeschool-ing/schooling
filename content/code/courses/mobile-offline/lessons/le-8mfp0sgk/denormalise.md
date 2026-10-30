---
title: Normalise less: the count kept on the course row
version: 1
---

**On a device it is often right to store a number that could be computed, as long as something
keeps it true.** The course list shows each course's session count and planned minutes. Computed,
that is a join and a `GROUP BY` over every session the person ever planned, on every launch.
Stored on the course row, it is a read of three rows. The price is that every write to `sessions`
must now also update `courses`, and the danger is the write that forgets.

This program keeps the two numbers on the course row in two ways: by the app's own code, the way it
is usually first written, and by triggers in the database. In app mode, adding and resizing a
session update the counts, and removing one does not, which is the bug that ships. Save it as
`denorm.ts` in `~/planner/model`:

```typescript
// denorm.ts: the course list's counts kept on the course row, by the app's code or by triggers.
import Database from "better-sqlite3";
import { courses, sessions } from "../data.ts";

const mode = process.argv[2]; // "app" or "triggers"
const db = new Database(":memory:");
db.exec(`
  CREATE TABLE courses (id TEXT PRIMARY KEY, name TEXT NOT NULL,
                        session_count INTEGER NOT NULL DEFAULT 0,
                        minutes_planned INTEGER NOT NULL DEFAULT 0);
  CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL REFERENCES courses (id),
                         date TEXT NOT NULL, minutes INTEGER NOT NULL, done INTEGER NOT NULL DEFAULT 0);
`);
if (mode === "triggers") {
  db.exec(`
    CREATE TRIGGER session_added AFTER INSERT ON sessions BEGIN
      UPDATE courses SET session_count = session_count + 1,
                         minutes_planned = minutes_planned + NEW.minutes WHERE id = NEW.course;
    END;
    CREATE TRIGGER session_removed AFTER DELETE ON sessions BEGIN
      UPDATE courses SET session_count = session_count - 1,
                         minutes_planned = minutes_planned - OLD.minutes WHERE id = OLD.course;
    END;
    CREATE TRIGGER session_changed AFTER UPDATE OF course, minutes ON sessions BEGIN
      UPDATE courses SET session_count = session_count - 1,
                         minutes_planned = minutes_planned - OLD.minutes WHERE id = OLD.course;
      UPDATE courses SET session_count = session_count + 1,
                         minutes_planned = minutes_planned + NEW.minutes WHERE id = NEW.course;
    END;
  `);
}

// The app's three writes. In "app" mode they keep the counts themselves, and one of them forgets.
const bump = db.prepare(
  "UPDATE courses SET session_count = session_count + ?, minutes_planned = minutes_planned + ? WHERE id = ?",
);
const add = db.transaction((id: string, course: string, date: string, minutes: number) => {
  db.prepare("INSERT INTO sessions (id, course, date, minutes) VALUES (?, ?, ?, ?)").run(id, course, date, minutes);
  if (mode === "app") bump.run(1, minutes, course);
});
const resize = db.transaction((id: string, minutes: number) => {
  const old = db.prepare("SELECT course, minutes FROM sessions WHERE id = ?").get(id) as { course: string; minutes: number };
  db.prepare("UPDATE sessions SET minutes = ? WHERE id = ?").run(minutes, id);
  if (mode === "app") bump.run(0, minutes - old.minutes, old.course);
});
const remove = db.transaction((id: string) => {
  db.prepare("DELETE FROM sessions WHERE id = ?").run(id); // the counts are not touched here
});

for (const c of courses) db.prepare("INSERT INTO courses (id, name) VALUES (?, ?)").run(c.id, c.name);
for (const s of sessions) add(s.id, s.course, s.date, s.minutes);
resize("s5", 50);
remove("s3");

console.log("the course list, read from the course rows alone:");
for (const r of db.prepare("SELECT name, session_count, minutes_planned FROM courses ORDER BY name").all()) {
  console.log(" ", r);
}
// The check: what the rows say against what the sessions add up to.
const drift = db.prepare(`
  SELECT c.id, c.session_count AS stored, count(s.id) AS counted
  FROM courses c LEFT JOIN sessions s ON s.course = c.id
  GROUP BY c.id HAVING stored <> counted OR c.minutes_planned <> coalesce(sum(s.minutes), 0)
`).all();
if (drift.length === 0) console.log("check: every stored count matches the sessions");
else console.log("check: drift in", drift);
```

Both runs load lesson 1's six sessions, lengthen `s5` to 50 minutes and remove `s3`, the guitar
session on 21 October:

```
ana@dev:~/planner/model$ node denorm.ts app
the course list, read from the course rows alone:
  { name: 'Guitar', session_count: 2, minutes_planned: 40 }
  { name: 'Spanish A2', session_count: 2, minutes_planned: 60 }
  { name: 'Statistics', session_count: 2, minutes_planned: 95 }
check: drift in [ { id: 'guitar', stored: 2, counted: 1 } ]
ana@dev:~/planner/model$ node denorm.ts triggers
the course list, read from the course rows alone:
  { name: 'Guitar', session_count: 1, minutes_planned: 20 }
  { name: 'Spanish A2', session_count: 2, minutes_planned: 60 }
  { name: 'Statistics', session_count: 2, minutes_planned: 95 }
check: every stored count matches the sessions
```

**In app mode the course list says Guitar has two sessions and 40 minutes, and it has one session
and 20.** Nothing failed. The screen draws a wrong number with full confidence, and keeps drawing it
until the next edit happens to touch the same course. The check at the end, which recomputes the
numbers from the sessions and compares, is the only thing that noticed.

With triggers, the database does the arithmetic on every insert, update and delete, in the same
transaction as the change, whichever code path made it. That is why the rule this course follows is
**keep a stored total in the same transaction as the rows it totals**, and let the database do it
where it can. Room supports triggers in a migration's SQL and a `@DatabaseView` for the read side;
Core Data and SwiftData keep derived values in code, so there the check matters more.

## What it costs

Every session write now writes two rows instead of one, and the schema has three triggers that a
person reading `sessions` has to know exist. Two more costs are less obvious.

- **Sync**: lesson 11 brings rows down from the server. If the server sends sessions, the triggers
  keep the counts right. If it also sends the course row with its own counts, the two must not both
  be applied, or the totals are counted twice.
- **The check is worth keeping.** Run it in tests, and in a debug build at launch. A stored total
  with no check is a claim nobody verifies.

The week screen is the opposite case. It is read often too, but its answer depends on the week the
person is looking at, so there is no single number to store; lesson 3's index on `date` is the
right answer there, not a column.
