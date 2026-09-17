---
title: Locking, when you want to be explicit about it
version: 1
---

Start with the fact that explains why databases feel as fast as they do:

> **A reader does not block a writer, and a writer does not block a reader.**

PostgreSQL, MySQL with InnoDB and Oracle all keep old versions of a row rather than overwriting it
in place, so a `SELECT` reads the version that was committed when its snapshot was taken while an
`UPDATE` writes a new one alongside. Nobody waits. This is what multiversion concurrency control
buys, and it is why the locking you have to think about is nearly always writer against writer.

**Writing a row locks it until the transaction ends.** Two transactions updating the same row: the
second waits at the `UPDATE` until the first commits or rolls back. That is automatic, it is what
makes `UPDATE products SET stock = stock - 1` safe against the lost update, and it is most of the
locking that happens in a working system.

## Locking a row you have only read

The lost update comes back when the decision happens in your application, because a plain `SELECT`
locks nothing:

```sql
BEGIN;
SELECT stock FROM products WHERE id = 7 FOR UPDATE;   -- 10, and now it is locked
-- application decides
UPDATE products SET stock = 9 WHERE id = 7;
COMMIT;
```

`FOR UPDATE` takes the same lock the `UPDATE` would have taken, at the moment you read. A second
transaction running the same code waits at its own `SELECT`, and reads 9 rather than 10 when it
gets through.

The variants, in decreasing strength:

| clause | blocks |
|---|---|
| `FOR UPDATE` | other writers and other lockers of the same row |
| `FOR NO KEY UPDATE` | the same, but permits a `FOR KEY SHARE` — what an ordinary `UPDATE` takes |
| `FOR SHARE` | writers, while permitting other readers to take the same lock |
| `FOR KEY SHARE` | changes to the key only — what a foreign key check takes |

`FOR SHARE` is the one people reach for when they mean *"nobody may change this while I decide"*
and several of them may be deciding at once. Be careful: two transactions holding a share lock that
both then want to upgrade is a deadlock, and it is the commonest way to write one on purpose.

## `NOWAIT` and `SKIP LOCKED`

Waiting is the default. Two other answers exist:

```sql
SELECT … FOR UPDATE NOWAIT;       -- error immediately if it is locked
SELECT … FOR UPDATE SKIP LOCKED;  -- silently leave out the rows that are locked
```

`NOWAIT` is for interactive work: a person clicking edit should be told *"somebody else has this
open"* rather than watching a spinner for ninety seconds.

`SKIP LOCKED` is how you write a job queue, and it is worth having in your hands:

```sql
BEGIN;
SELECT id, payload FROM jobs
WHERE  status = 'pending'
ORDER BY created_at
LIMIT  1
FOR UPDATE SKIP LOCKED;

UPDATE jobs SET status = 'running' WHERE id = $1;
COMMIT;
```

Ten workers run this at once. Each takes the first pending job that nobody else has locked, so they
never collide and never queue behind each other. Without `SKIP LOCKED` all ten wait for the same
row and the queue processes one job at a time; with it the table is a work queue and needs no
broker. PostgreSQL, MySQL 8 and Oracle have it.

## The optimistic alternative

Locking is pessimistic: you assume a conflict and prevent it. The other approach assumes there will
not be one and detects it if there is, with a version column:

```sql
SELECT id, name, version FROM documents WHERE id = 7;   -- version 4, no lock taken

UPDATE documents SET name = $1, version = 5
WHERE  id = 7 AND version = 4;
```

If somebody else saved in between, the row is at version 5, the `WHERE` matches nothing, and
**zero rows are updated**. No error — you have to look at the affected-row count and treat zero as
a conflict, which is the part people forget.

This is what most ORMs mean by optimistic locking, and it is the right shape when the gap between
read and write includes a human: you cannot hold a database lock while somebody edits a form for
twenty minutes. Lesson 11 comes back to it.

## Locks on things that are not rows

```sql
SELECT pg_advisory_xact_lock(4815);
```

An advisory lock is a number the database will let one transaction hold at a time. It protects
nothing by itself — it means whatever the code agrees it means — and it is the tool for *"only one
importer may run at a time"*, where there is no row to lock because the thing being protected is a
process.

Use a constant defined in one place, and prefer the `xact` form, which is released at the end of
the transaction. The session-scoped version has to be released by hand, and a connection returned
to a pool while still holding one takes the lock with it.

## Two habits

**Hold locks for as little time as possible.** Take them as late as you can and commit promptly.
Every one of the pathologies in the next two sections gets worse the longer they are held.

**Take them in a consistent order.** Two transactions that lock row 1 then row 2 will queue. Two
that lock them in opposite orders will deadlock, which is the next section — and consistent
ordering is the fix that costs nothing.
