---
title: The four isolation levels, and the one you are on
version: 1
---

The standard defines four levels, and it defines them **by which of the anomalies they forbid**
rather than by how they work:

| level | dirty read | non-repeatable read | phantom |
|---|---|---|---|
| `READ UNCOMMITTED` | possible | possible | possible |
| `READ COMMITTED` | prevented | possible | possible |
| `REPEATABLE READ` | prevented | prevented | possible |
| `SERIALIZABLE` | prevented | prevented | prevented |

That is the table in every textbook, and it is worth knowing two things about it before you use it.

**It is a floor, not a description.** A level says what an engine may not allow. Engines routinely
give you more than the row requires, so two databases at "the same" level behave differently.

**Lost update and write skew are missing from it.** The 1992 standard names three anomalies, and
the two you are most likely to meet in an application are not among them. A level that forbids
everything in this table can still let you lose an update.

## Setting it

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;     -- PostgreSQL
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;          -- before the statements, both engines
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;-- for every transaction on this connection
```

And to find out where you are, which is the more useful statement:

```sql
SHOW transaction_isolation;               -- PostgreSQL
SELECT @@transaction_isolation;           -- MySQL
```

## The defaults are not the same

**PostgreSQL defaults to `READ COMMITTED`. MySQL defaults to `REPEATABLE READ`.**

The same application, deployed on both, runs at two different levels — and a concurrency bug that
is impossible on one is routine on the other, which is a genuinely unpleasant way to discover this.

## What each engine actually does

**PostgreSQL.** `READ UNCOMMITTED` exists as a spelling and behaves as `READ COMMITTED`: the
storage keeps old row versions rather than overwriting in place, so there is no uncommitted version
to read even if you ask for one. A dirty read is not a thing that can happen here.

`READ COMMITTED` gives **each statement** a fresh view of the committed data. That is the whole
explanation of the non-repeatable read: two statements, two views.

`REPEATABLE READ` gives the **whole transaction** one view, taken at the first statement. That
prevents phantoms too, which is stricter than the table demands, so PostgreSQL's middle level is
snapshot isolation rather than the standard's. It also means a conflicting `UPDATE` cannot simply
wait and proceed — the transaction is aborted with *"could not serialize access due to concurrent
update"*, and you are expected to run it again.

`SERIALIZABLE` adds tracking of what each transaction read, and aborts one of any set whose
outcome could not have come from running them one at a time. It is the only level here that stops
write skew.

**MySQL with InnoDB.** The default `REPEATABLE READ` is snapshot-based for ordinary reads, and it
has a behaviour that catches people: a plain `SELECT` reads the snapshot, while `UPDATE`, `DELETE`
and `SELECT … FOR UPDATE` read the **latest committed** version instead. So a transaction can read
10, update the row, and find it has written from a value of 12 that it never saw.

It also takes gap locks — locks on the space between index entries — so a locking read in this
level blocks the inserts that would be phantoms. That makes it stronger than the standard requires
in one direction and weaker in another, and it is why porting concurrency logic between MySQL and
PostgreSQL deserves a careful read rather than a copy.

**Oracle** has two: `READ COMMITTED`, the default, and `SERIALIZABLE`, which is snapshot isolation
and therefore allows write skew despite the name. It has no `REPEATABLE READ` and no
`READ UNCOMMITTED`.

**SQLite** has one writer at a time, so it is serializable by default, and the concurrency question
becomes a throughput question instead.

## Which to choose

**`READ COMMITTED` for almost everything.** It is the default in most places for good reason: it
never shows you uncommitted work, it never aborts your transaction for a conflict, and the
anomalies it allows are ones you can handle where they matter.

**`REPEATABLE READ` when a transaction reads the same data more than once** and the answers have to
agree — a report of several queries, an export, a reconciliation. One view for the whole
transaction is exactly the thing being asked for.

**`SERIALIZABLE` when a decision depends on a condition over rows you are not the one writing.**
That is the write-skew shape, it is the next section, and choosing this level is choosing to write
a retry loop.

And **the level is not a substitute for a constraint**. A unique index stops two rows with the same
email at any isolation level, on any engine, including the one your colleague is using from a
script. Reach for the declaration first and the level second.
