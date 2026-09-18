---
title: Being the developer, not the administrator
version: 1
---

You are on a project, the database is Oracle, somebody else runs it, and you have a schema and a
login. This section is what is actually in your hands — and there is more of it than the last
section's constraints suggest, because the largest performance factor on an Oracle system is a
property of the SQL you send.

## Bind variables, which matter more here than anywhere else in this course

This is the single most valuable thing in the lesson, and it is the same practice lesson 11 taught
for a different reason.

Oracle parses a statement and keeps the result — the plan and everything around it — in a shared
memory area. A statement that arrives with its values glued into the text is **a different
statement every time**:

```sql
SELECT id, name FROM customers WHERE email = 'ana@example.com'
SELECT id, name FROM customers WHERE email = 'bruno@example.com'
```

Two texts, two hard parses, two entries in the shared pool. At four hundred addresses that is four
hundred of each. Hard parsing is expensive, it takes latches that everything else also wants, and a
pool full of one-use statements has room for nothing worth keeping. On a busy system this presents
as the whole database slowing down, with no single query looking slow.

With a bind variable it is one statement:

```sql
SELECT id, name FROM customers WHERE email = :email
```

One text, one parse, one entry, and the values supplied separately. That is **exactly** the
parameterised statement lesson 11 asked for to keep SQL injection impossible — the same practice,
and on Oracle it is also the difference between a system that scales and one that does not.

**Every ORM and driver does this by default.** The systems that suffer are the ones with SQL built
by string concatenation, which lesson 11 already named as the thing not to do.

There is one honest exception. A column whose values are wildly skewed — a status where ninety-nine
per cent of rows are `done` — can want a *different* plan per value, and a bind variable hides the
value from the planner at parse time. Oracle has machinery for this, called adaptive cursor sharing
and bind peeking. It is worth knowing the exception exists; it is not a reason to concatenate.

## Read the plan, with the vocabulary you already have

Lesson 10's method transfers whole. Get the plan for the statement that ran,
`DBMS_XPLAN.DISPLAY_CURSOR` with `ALLSTATS LAST`, put estimated against actual rows on every line,
and find the first line where they diverge badly. `TABLE ACCESS FULL` on a large table under a
`NESTED LOOPS` is the missing-index shape from lesson 10 in Oracle's words.

## What to ask for, and how

**An index.** Bring the statement, the plan, the row counts and the selectivity of the column, and
say what you expect to change. Lesson 9's warnings are the DBA's warnings too: an index costs every
write, and a table with fifteen of them has a problem rather than a solution.

**Statistics.** Oracle's planner depends on statistics as PostgreSQL's does, and a table loaded in
bulk overnight can be planned on yesterday's numbers. "Have the statistics been gathered on this
table since the load" is a legitimate and specific question.

**A look at the performance history.** Ask for the AWR report over the window, and accept "we do
not license that" as an answer with a follow-up rather than a dead end: `V$SQL` for the statement,
and the elapsed time and execution count on it.

## What is fully yours

The list is longer than it feels on the first week:

- **the SQL you write**, which is most of the performance
- **bind variables**, which is most of the rest
- **the transaction boundaries**: what is in one, and how long it is open
- **the constraints in your own schema**, which lesson 3 argued for and no licence affects
- **committing what you started** in a client window, which is the last section's support call
- **not putting a function on an indexed column** in a `WHERE`, which is lesson 9 and is free

None of that needs a privilege, a licence or a meeting.

## And the thing to keep hold of

An Oracle system in a large organisation can feel like a place where nothing can be changed. Some
of that is true and is contractual. But the query you are about to write is yours, it is the part
of the system that decides most of its behaviour, and every lesson in this course applies to it.
