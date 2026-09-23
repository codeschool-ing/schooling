---
title: What an open transaction costs while it is open
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"A timeline from Tuesday to now. A highlighted bar spans almost the whole of it, labelled one transaction, open, doing nothing. Below it, a bar showing what VACUUM can reclaim: a small shaded piece before Tuesday, and then nothing, with a dashed vertical line at the transaction's start labelled the oldest running transaction is the line it cannot pass. Three lines below list what grows meanwhile: dead rows in the table, dead entries in every index, and autovacuum running and reclaiming nothing.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">One transaction left open on Tuesday, and the cost is measured in wall-clock time rather than in work done.</text><path d=\"M110 62 L660 62\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M130 56 L130 68\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"130\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">Tuesday</text><path d=\"M300 56 L300 68\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"300\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">Wednesday</text><path d=\"M470 56 L470 68\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"470\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">Thursday</text><path d=\"M640 56 L640 68\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"640\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">now</text><rect x=\"130\" y=\"96\" width=\"510\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"385\" y=\"109\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">one transaction, open, doing nothing</text><text x=\"14\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">VACUUM can reclaim</text><rect x=\"110\" y=\"138\" width=\"20\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"130\" y=\"138\" width=\"510\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"385\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">and nothing from here onwards, for as long as it stays open</text><path d=\"M130 132 L130 170\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><text x=\"136\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the oldest running transaction is the line it cannot pass</text><text x=\"14\" y=\"210\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dead rows accumulate in the table</text><text x=\"300\" y=\"210\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→ the table grows and scans get slower</text><text x=\"14\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dead entries accumulate in every index</text><text x=\"300\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→ the indexes grow too</text><text x=\"14\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">autovacuum runs and reclaims nothing</text><text x=\"300\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→ and keeps running</text><text x=\"14\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">The table gets bigger while the number of live rows stays the same. That is bloat, and it does not go away when the transaction finally ends.</text></svg>", "caption": "The bar is the whole cost. Nothing about it depends on what the transaction did — only on how long it has been there."}
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

```localised
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
