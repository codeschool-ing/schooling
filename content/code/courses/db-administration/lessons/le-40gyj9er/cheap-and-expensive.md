---
title: Cheap changes and expensive ones
version: 1
---

Every `ALTER TABLE` takes its lock the same way. **What differs is how long it keeps it**, and that
depends on one question: does PostgreSQL have to touch every row? Some changes only edit the
catalogue, the table's description, and finish in milliseconds at any size. Others **rewrite the
table**: they write a new copy of every row into a new file and swap it in, holding `ACCESS
EXCLUSIVE` the whole time, so that the table is closed for as long as the copy takes.

Two things make a rewrite visible. The table's file changes, because the new copy is a new file,
and `pg_relation_filepath` (lesson 4) prints a different name. And PostgreSQL says so at the
`DEBUG1` level, which `client_min_messages` can show in your own session:

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SET client_min_messages = debug1;
SET
Time: 0.292 ms

shop=# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)

Time: 0.826 ms

shop=# ALTER TABLE orders_live ADD COLUMN channel text NOT NULL DEFAULT 'web';
ALTER TABLE
Time: 19.067 ms

shop=# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)

Time: 0.405 ms

shop=# BEGIN;
BEGIN
Time: 0.273 ms

shop=*# ALTER TABLE orders_live ADD COLUMN token uuid DEFAULT gen_random_uuid();
DEBUG:  building index "pg_toast_16427_index" on table "pg_toast_16427" serially
DEBUG:  index "pg_toast_16427_index" can safely use deduplication
DEBUG:  rewriting table "orders_live"
ALTER TABLE
Time: 2814.463 ms (00:02.814)

shop=*# ALTER TABLE orders_live ALTER COLUMN total_cents TYPE bigint;
DEBUG:  building index "pg_toast_16432_index" on table "pg_toast_16432" serially
DEBUG:  index "pg_toast_16432_index" can safely use deduplication
DEBUG:  rewriting table "orders_live"
ALTER TABLE
Time: 2048.938 ms (00:02.049)

shop=*# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16432
(1 row)

Time: 0.817 ms

shop=*# SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
        mode         
---------------------
 ShareLock
 AccessExclusiveLock
(2 rows)

Time: 1.092 ms

shop=*# ROLLBACK;
ROLLBACK
Time: 31.254 ms

shop=# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)

Time: 0.321 ms

shop=# ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(20);
DEBUG:  sending cancel to blocking autovacuum PID 259
DEBUG:  building index "pg_toast_16437_index" on table "pg_toast_16437" serially
DEBUG:  index "pg_toast_16437_index" can safely use deduplication
DEBUG:  rewriting table "orders_live"
ALTER TABLE
Time: 2702.689 ms (00:02.703)

shop=# ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(40);
ALTER TABLE
Time: 9.340 ms

shop=# \q
```

The lines about `pg_toast` indexes are the rewrite building a new side table for long values; the
line to look for is **`rewriting table "orders_live"`**. A line saying `sending cancel to blocking
autovacuum`, if your run prints one, is the `ALTER` cancelling an autovacuum that was working on the
new table and held a conflicting lock; autovacuum comes back to it later.

## Adding a column

**A column with a constant default is instant**, `NOT NULL` included. Since PostgreSQL 11 the
default is stored once in the catalogue and handed to every old row when it is read, so no row is
touched; the file kept its name, and the time was a few milliseconds. Before version 11 the same
command rewrote the table, which is why older advice says never to add a column with a default.

**A volatile default rewrites.** `gen_random_uuid()` gives every row a different value, so the
values have to be written into the rows, and the file changed. Under three seconds for a million
rows on the recording machine. If it scaled evenly, a billion rows would be the better part of an
hour, with the table closed throughout.

## Changing a type

**Changing `integer` to `bigint` rewrites**, because a `bigint` is eight bytes and an `integer`
four, so every row changes shape. `pg_locks` lists `AccessExclusiveLock` among the session's locks
on the table, and it stays held until the transaction ends.

Some type changes need no rewrite, and the last two commands show the pair worth remembering.
`text` to `varchar(20)` rewrote, because the new limit had to be applied. `varchar(20)` to
`varchar(40)` was instant: **raising a `varchar` limit, or removing it, cannot invalidate any row**,
so PostgreSQL only edits the catalogue. Lowering one would have to check every row.

| change | rewrite? |
| --- | --- |
| add a column, no default or a constant one | no |
| add a column with a volatile default | yes |
| drop a column | no: it is marked dropped, and the space is reused as rows are rewritten |
| `integer` to `bigint`, `text` to `integer`, and most type changes | yes |
| `varchar(n)` to a larger `n`, or to `text` | no |
| `SET NOT NULL` | no rewrite, but a full scan under the lock, unless a valid `CHECK` proves it (next section) |

When in doubt, try it on a copy like this one with `client_min_messages` at `debug1`, and read the
file name before and after.

## Schema changes are transactional

The `token` column and the `bigint` were never kept. Both happened inside `BEGIN`, and `ROLLBACK`
undid them: the file name went back to the one before, and the table is as it was. **PostgreSQL
can roll back `ALTER TABLE`**, along with almost every other schema change, which MySQL and Oracle
cannot. A migration that fails halfway inside one transaction leaves nothing half done. The cost is
that every lock it took is held until the end of that transaction, so a long migration in one
transaction is one long lock.
