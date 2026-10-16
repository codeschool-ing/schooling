---
title: A restore you do on purpose, with a stopwatch
version: 1
---

Lessons 1 to 6 restored a database four different ways. Each time it was a demonstration: one
person, a quiet machine, the right answer known in advance. A **restore drill** is the same act made
into a routine: the newest backup restored somewhere harmless, on a schedule, proved against the live
database, timed phase by phase, written down and thrown away. It answers three questions no other
check in this course can:

- **Does the newest backup restore?** Not the one tested last spring. Backups break in ordinary ways
  between tests: a configuration change, an upgrade, a full disk, a credential rotated.
- **Is what comes back the database?** Lesson 1's comparison, done against a database that has grown
  tables since the report was written.
- **How long does it take?** Measured, by phase, on real data. Lesson 8 needs that number, and the
  only honest source of it is a restore somebody timed.

A drill is not a restore test somebody remembers to run before an audit. Its value is in the
**repetition**: a failure that appears in the week it happens, while the previous good backup still
exists, and a duration that is seen to grow before it becomes a surprise.

## It already exists, in the platform you are reading this on

The school this course is part of runs a drill of exactly this shape against its own production
database. It clones the database from its point-in-time backups onto a new, temporary server, runs one
report against both the live database and the clone, demands that the two outputs be identical
character for character, and deletes the clone whether the check passed or failed. Its notes say the
same thing this course has been saying, in their own words: a declared backup is a belief, and only
a restore answers whether the bytes come back.

Two of its decisions are worth borrowing. **The report finds the tables itself**, so a table added
next month is inside next month's drill without anybody remembering to edit it. And **the clone
never touches the live server**: the restore is the destructive operation, and doing it over the
database being tested would destroy the thing you need if the restore turned out to be bad. This
lesson builds a smaller version of both on your machine, with the second server on port 5433 as the
harmless place.
