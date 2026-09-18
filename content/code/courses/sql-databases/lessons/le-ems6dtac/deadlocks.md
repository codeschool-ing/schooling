---
title: Deadlocks are normal, and they are your fault
version: 1
---

Two transfers at the same moment, in opposite directions:

```
T1  (100 from Ana to Bruno)           T2  (50 from Bruno to Ana)
BEGIN                                 BEGIN
UPDATE accounts … WHERE id = 1        UPDATE accounts … WHERE id = 2
  → holds the lock on row 1             → holds the lock on row 2
UPDATE accounts … WHERE id = 2        UPDATE accounts … WHERE id = 1
  → waits for T2                        → waits for T1
```

Each holds what the other needs. Neither can proceed and neither will give up. That is a deadlock,
and no amount of waiting resolves it.

## What the database does about it

It notices, and it kills one of them:

```
ERROR:  deadlock detected
DETAIL: Process 8231 waits for ShareLock on transaction 993; blocked by process 8244.
        Process 8244 waits for ShareLock on transaction 991; blocked by process 8231.
HINT:   See server log for query details.
```

PostgreSQL looks for a cycle in the wait graph after a transaction has been waiting for one second
— `deadlock_timeout`, and a second is long because the check is not free and most waits are
ordinary contention that clears on its own. MySQL detects one immediately and reports error 1213.

The important part is what this is **not**. It is not corruption, it is not a crash, and it is not
a bug in the database. One transaction is rolled back cleanly, the other proceeds, and the victim's
application is told. A deadlock is the database noticing a mistake in your locking order and
resolving it the only way it can.

Which is why the first response is not alarm. It is: **is this rare enough to retry, or often
enough to fix the ordering?** Both answers are legitimate and the second one is usually available.

## The cause, almost every time

**Two transactions take the same locks in different orders.** In the transfer above, T1 goes 1 then
2 and T2 goes 2 then 1. Make both go in ascending order of id and the cycle cannot form: whichever
gets row 1 first also gets row 2, and the other simply waits and then proceeds.

```sql
UPDATE accounts SET balance = balance + delta
FROM  (VALUES (1, -100), (2, 100)) AS t(id, delta)
WHERE accounts.id = t.id
ORDER BY accounts.id;
```

Or, if the updates are separate statements, sort the ids in the application before issuing them.
It is two lines of code and it removes an entire class of incident.

The same rule applies to a batch: `UPDATE … WHERE id IN (…)` takes the row locks in whatever order
the plan produces them, so two batches over overlapping sets can deadlock. Ordering the input makes
them queue instead.

## Three other sources worth recognising

**Lock upgrades.** Two transactions take `FOR SHARE` on a row, then both try to update it. Each
waits for the other to release its share lock. The fix is to take `FOR UPDATE` at the start, when
you already know you intend to write — **take the strongest lock you will need, as early as you
need it.**

**Foreign keys.** Inserting a child row takes a lock on the parent to check the reference still
exists. Two transactions inserting children of two parents, in opposite orders, deadlock without
either of them naming a parent row. This one is genuinely surprising the first time.

**Index and gap locks in MySQL.** At `REPEATABLE READ`, InnoDB locks the gaps between index entries
to stop phantoms, so two inserts that touch no common row can still contend over the same gap.
Deadlocks that make no sense in terms of rows often make sense in terms of the index.

## Reading the evidence

Do not guess at the ordering. Both engines tell you:

```sql
SHOW ENGINE INNODB STATUS;      -- MySQL: the LATEST DETECTED DEADLOCK section, with both queries
```

PostgreSQL writes both statements to the server log when it detects one, and `log_lock_waits = on`
adds an entry for any wait longer than `deadlock_timeout`, which is how you find the contention
before it becomes a cycle.

And keep the distinction between the two errors, because they have different fixes:

| | means | fix |
|---|---|---|
| **deadlock detected** | a cycle: nobody can proceed | change the order locks are taken in |
| **lock wait timeout** | ordinary contention that took too long | shorten the transaction holding it |

A lock wait timeout is somebody holding a lock for a long time. Reordering will not help; the
`long-transactions` section will.

## And retry anyway

You cannot design deadlocks out entirely. A schema change, a new query, a batch job somebody added
— each is a chance for a new pair of orderings. Consistent ordering makes them rare, and rare is
not never.

So the deadlock error joins the serialization failure from the previous section on the list of
things your application must be able to run again. That is one section away, and it is the same
loop for both.
