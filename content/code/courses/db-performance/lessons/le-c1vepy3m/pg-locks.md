---
title: A chain to look at, and pg_locks
version: 1
---

Lesson 12 made sessions wait for each other and watched from inside the waiting windows. On a real
server nobody is inside those windows. What you see is the symptom: a page that used to load in a
few milliseconds now times out, the connection count climbs, and **nothing in the slow query
itself explains it.** The question this lesson answers is the one lesson 12 ended on, asked from
the outside and while it is happening: what is it waiting for, and who is holding that?

The usual instinct is to find the slow query and look at its plan. When the time is spent waiting
for a lock, the plan is fine and the query is innocent; **the culprit is a different session, and
often one that is doing nothing at all.**

## Building the chain

Open four terminals with `psql market`. Windows A, B and C will make the trouble; window D is where
you investigate. First, in each of A, B and C, ask for the session's **process id**, the number the
server knows it by:

```
market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           5792
(1 row)

Time: 0.797 ms
```

```
market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           5794
(1 row)

Time: 0.630 ms
```

```
market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           5796
(1 row)

Time: 0.636 ms
```

Yours will be other numbers; note them, because everything below is in terms of them. Now window A
changes order 1 inside a transaction, and then does nothing. Picture an application that opened a
transaction, ran an update and went off to call a payment service that is not answering:

```
market=# BEGIN;
BEGIN
Time: 0.177 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 2.112 ms
```

Window B, in its own transaction, changes order 2 and then order 1, and waits for window A:

```
market=# BEGIN;
BEGIN
Time: 0.119 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 1.723 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
```

Window C changes order 2, and waits for window B:

```
market=# UPDATE orders SET status = 'cancelled' WHERE id = 2;
```

Three sessions, two of them stuck. Leave them for twenty seconds, then go to window D.

## Reading `pg_locks`

`pg_locks` has one row for every lock held or requested in the server right now. On a busy system that
is a lot of rows. This query keeps only the kinds that matter here: the table lock on `orders`, and
the two kinds a row lock involves, which the next paragraphs explain:

```
market=# SELECT pid, locktype, relation::regclass, page, tuple, transactionid, mode, granted FROM pg_locks WHERE pid <> pg_backend_pid() AND locktype IN ('relation', 'transactionid', 'tuple') AND (relation IS NULL OR relation = 'orders'::regclass) ORDER BY pid, granted DESC, locktype;
 pid  |   locktype    | relation | page | tuple | transactionid |       mode       | granted 
------+---------------+----------+------+-------+---------------+------------------+---------
 5792 | relation      | orders   |      |       |               | RowExclusiveLock | t
 5792 | transactionid |          |      |       |       1609205 | ExclusiveLock    | t
 5794 | relation      | orders   |      |       |               | RowExclusiveLock | t
 5794 | transactionid |          |      |       |       1609206 | ExclusiveLock    | t
 5794 | tuple         | orders   |    0 |     1 |               | ExclusiveLock    | t
 5794 | transactionid |          |      |       |       1609205 | ShareLock        | f
 5796 | relation      | orders   |      |       |               | RowExclusiveLock | t
 5796 | transactionid |          |      |       |       1609207 | ExclusiveLock    | t
 5796 | tuple         | orders   |    0 |     2 |               | ExclusiveLock    | t
 5796 | transactionid |          |      |       |       1609206 | ShareLock        | f
(10 rows)

Time: 2.457 ms
```

The column to read first is **`granted`**. Every row with `t` is a lock somebody has; the two rows
with `f` are the requests that are waiting, and those are the whole problem.

**Each transaction holds an `ExclusiveLock` on its own transaction id**, from the moment it first
changes something until it ends: window A (5792) holds transaction 1609205, window B (5794) holds
1609206, window C (5796) holds 1609207. That lock is how other sessions wait for a transaction.

**A row lock is not in this view.** Lesson 12 said row locks live in the rows themselves, and here
is the consequence: nothing in `pg_locks` says "5792 has locked order 1". What you see instead is
the wait. Window B found order 1 marked as changed by transaction 1609205. So it asked for a
**`ShareLock` on transaction 1609205**, and was not granted it: it is waiting for window A's
transaction to end, whatever that transaction does with the row. Window C waits in the same way for 1609206,
window B's transaction.

**The `tuple` rows are the queue for one row.** Window B holds an `ExclusiveLock` on tuple 1 of
page 0 of `orders`, which is order 1's physical place, and window C holds the one on page 0, tuple
2, order 2. A waiter takes the tuple lock so that, if several sessions wait for the same row, they
get it in the order they arrived rather than all at once.

And the table locks: all three hold `RowExclusiveLock` on `orders`, which never conflict with each
other, as row 3 of lesson 12's matrix says. **The waiting here is entirely about rows**, which is
why a query on `orders` that changes nothing, or changes other rows, still goes through while this
is happening.

## Why not stop at `pg_locks`

Everything needed to work out who waits for whom is in those ten rows: match each ungranted
`transactionid` to the session holding the same `transactionid` with `ExclusiveLock`. Doing that by
hand on a server with three hundred sessions is slow, and it gets the rules wrong for every kind of
lock but this one. **PostgreSQL does the matching for you**, in a function the next section uses;
`pg_locks` stays the place to go when you need to know exactly which lock, on what.
