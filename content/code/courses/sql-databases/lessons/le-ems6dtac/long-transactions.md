---
title: What an open transaction costs while it is open
version: 1
---

A transaction is cheap to start and cheap to finish. It is holding one open that costs, and the
cost grows with the wall-clock time rather than with the work done — so the most expensive
transaction in most systems is one that is doing nothing at all.

## Four things it is holding

**Every lock it has taken.** Until it ends, the rows it wrote are locked. Anybody who wants to
write them waits, and lesson 3's queue forms behind that: one `ALTER TABLE` blocked by a long
transaction blocks everything that arrives afterwards, including the reads.

**Every row version it might still need to see.** This is the PostgreSQL-specific one and it is the
one that damages a database rather than a request. An `UPDATE` does not overwrite; it writes a new
version and leaves the old one for whoever might still be looking. `VACUUM` reclaims the dead ones
— but it can only reclaim versions older than the oldest running transaction. One transaction open
since Tuesday means nothing written since Tuesday can be cleaned up:

```
dead rows accumulate in the table          → the table grows and scans get slower
dead entries accumulate in every index     → the indexes grow too
autovacuum runs and reclaims nothing       → and keeps running
```

The table gets bigger while the number of live rows stays the same. That is bloat, it does not go
away when the transaction finally ends, and repairing it needs a rewrite of the table.

**A place in the transaction id sequence.** Left long enough — weeks, on a busy system — an open
transaction stops the database from advancing past a wraparound point, and PostgreSQL will refuse
new writes to protect itself. It is rare and it is the way a long transaction takes a whole system
down rather than one query.

**And a standby's ability to apply changes**, if replicas are configured to wait for their readers.
A long query on a replica holds up replay, or gets cancelled; either way the transaction on one
machine is affecting another.

MySQL has its own version of the second one: undo log entries are kept for as long as any
transaction might need them, the history list grows, and purge falls behind.

## `idle in transaction`, which is the usual culprit

```sql
SELECT pid, state, now() - xact_start AS open_for, left(query, 60)
FROM   pg_stat_activity
WHERE  state <> 'idle'
ORDER BY xact_start;
```

Run that on a system with a bloat problem and you will often find a row like this:

```
 pid  |        state        | open_for |            query
 8231 | idle in transaction | 02:14:37 | SELECT id FROM settings WHERE key = 'x'
```

Two hours. The query finished in a millisecond; the transaction is still open because nobody
committed. **`idle in transaction` means the connection is holding everything above and doing
nothing with it.**

It is nearly always one of three things: a driver with autocommit off, where a stray `SELECT`
opened a transaction nobody meant to open; a framework that opens one at the start of a request and
closes it at the end; or code that called out to something slow in the middle.

PostgreSQL has a blunt instrument for it, and it is worth setting:

```sql
ALTER SYSTEM SET idle_in_transaction_session_timeout = '60s';
```

Anything idle inside a transaction for a minute is killed. The application sees a dropped
connection, which is a bug report, and a bug report beats bloat.

## The rule that prevents most of it

> **Do nothing inside a transaction that waits on something outside the database.**

An HTTP call to a payment provider. Sending an email. Writing to object storage. Waiting for a user
to click a button. Each turns the length of your transaction into somebody else's latency, and a
provider that takes thirty seconds to answer has just held your locks for thirty seconds.

The shape that works is to do the slow thing outside, and use the database to record intent:

```
BEGIN; INSERT INTO payments (status) VALUES ('pending') RETURNING id; COMMIT;
   → call the payment provider, however long it takes
BEGIN; UPDATE payments SET status = 'settled' WHERE id = $1; COMMIT;
```

Two short transactions with the slow part between them, and a row that records what state the
world is in if the process dies in the middle. That last part is the real benefit: the transaction
that surrounded everything did not survive a crash either, it just felt like it would.

## And big writes get batched

Lesson 3's backfill was batched for exactly these reasons: a single `UPDATE` over ten million rows
is one transaction that holds locks and dead versions for its whole run, and it cannot be stopped
without losing all of it. In batches of a few thousand, each committing, the locks are brief, the
dead rows are reclaimable as it goes, and a batch that fails costs one batch.

The trade is honest and worth saying out loud: **you gave up atomicity over the whole job.** Half
the rows are updated if it stops in the middle, so the job has to be written to be resumable —
which usually means a `WHERE` clause that skips the rows already done.
