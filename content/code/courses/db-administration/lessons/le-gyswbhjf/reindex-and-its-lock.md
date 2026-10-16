---
title: REINDEX, and who waits while it runs
version: 1
---

`REINDEX` builds the index again from the table, into a new file, and throws the old file away.
Lesson 4 showed that a table's file is named by a number that changes when the table is rewritten,
and an index behaves the same way:

```
shop=# SELECT pg_relation_filepath('orders_created_at');
 pg_relation_filepath 
----------------------
 base/16386/16411
(1 row)

shop=# REINDEX INDEX orders_created_at;
REINDEX

shop=# SELECT pg_relation_filepath('orders_created_at');
 pg_relation_filepath 
----------------------
 base/16386/16425
(1 row)
```

It comes in sizes: `REINDEX INDEX` for one, `REINDEX TABLE` for every index of a table, and
`SCHEMA`, `DATABASE` and `SYSTEM` above that. The size of the job is not the interesting part. The
lock is.

## Three terminals and one REINDEX

A rebuild of this index takes under a second, which is too short to look at anything while it
runs. So the first terminal opens a transaction, reindexes inside it and keeps the transaction
open: the locks `REINDEX` takes are held until `COMMIT`, which is what a long rebuild of a large
index does anyway, for minutes. Open four terminals on the server, run `psql shop` in each, and
type `\timing on` in the second and the third, so they say how long each statement took.

In terminal 1:

```
shop=# BEGIN;
BEGIN

shop=*# REINDEX INDEX orders_created_at;
REINDEX
```

In terminal 2, a query that has nothing to do with `created_at`. It hangs:

```
shop=# SELECT count(*) FROM orders WHERE customer_id = 42;
 count 
-------
    20
(1 row)

Time: 6880.993 ms (00:06.881)
```

In terminal 3, an update of one row. It hangs too:

```
shop=# UPDATE orders SET total_cents = total_cents WHERE id = 1;
UPDATE 1
Time: 5280.572 ms (00:05.281)
```

The `Time:` lines are how long each one waited, and they were printed only at the end, once
terminal 1 let go. While they were waiting, terminal 4 asked `pg_locks` who holds what on the
table and the index:

```
shop=# SELECT l.pid, l.relation::regclass, l.mode, l.granted, pg_blocking_pids(l.pid) AS blocked_by FROM pg_locks l WHERE l.relation IN ('orders'::regclass, 'orders_created_at'::regclass) ORDER BY l.pid, l.relation;
 pid |     relation      |        mode         | granted | blocked_by 
-----+-------------------+---------------------+---------+------------
 319 | orders            | AccessShareLock     | t       | {324}
 319 | orders_created_at | AccessShareLock     | f       | {324}
 321 | orders            | RowExclusiveLock    | f       | {324}
 324 | orders            | ShareLock           | t       | {}
 324 | orders_created_at | AccessExclusiveLock | t       | {}
(5 rows)
```

Each row is one lock, held (`granted` is `t`) or asked for and not given (`f`). The process ids
are your terminals' and will be other numbers on your machine; read them by their locks.

- The process with **`ShareLock` on `orders` and `AccessExclusiveLock` on `orders_created_at`** is
  terminal 1, the `REINDEX`. Nothing blocks it.
- The process with `RowExclusiveLock` on `orders`, not granted, is terminal 3. **An update needs
  a lock that conflicts with `ShareLock`**, so every write to the table waits for the whole
  rebuild.
- The process with `AccessShareLock` on `orders` granted and on `orders_created_at` not granted is
  terminal 2. Its query never uses that index, and it waits for it anyway.

That last row is the one people do not expect. **Before choosing a plan, the planner opens every
index of the table**, to know what it could use, and opening one takes `AccessShareLock`, which
conflicts with nothing except the `AccessExclusiveLock` that `REINDEX` holds. So the documentation's
"locks out writes but not reads of the index's parent table" is true of the table and not of the
queries: almost every
query that touches the table queues behind the rebuild of any one of its indexes.
`pg_blocking_pids` names the culprit on both waiting rows.

Back in terminal 1, the end of it:

```
shop=*# COMMIT;
COMMIT
```

The two waiting statements finished the moment it committed. Lesson 22 shows what happens when a
statement like this one waits behind a long query instead of in front of it, and why everybody
then queues behind both. `db-performance` lessons 12 and 13 cover locks in general.

**On a live table, a plain `REINDEX` is a short outage for that table**, as long as the build takes.
For the indexes of `orders` that is under half a second, as the next section times. For an index of a few gigabytes it is
minutes, and nothing that reads or writes the table moves during them. That is the reason the next
section exists.
