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
shop=# SET client_min_messages = debug1;
shop=# SELECT pg_relation_filepath('orders_live');
shop=# ALTER TABLE orders_live ADD COLUMN channel text NOT NULL DEFAULT 'web';
shop=# SELECT pg_relation_filepath('orders_live');
shop=# BEGIN;
shop=*# ALTER TABLE orders_live ADD COLUMN token uuid DEFAULT gen_random_uuid();
shop=*# ALTER TABLE orders_live ALTER COLUMN total_cents TYPE bigint;
shop=*# SELECT pg_relation_filepath('orders_live');
shop=*# SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
shop=*# ROLLBACK;
shop=# SELECT pg_relation_filepath('orders_live');
shop=# ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(20);
shop=# ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(40);
shop=# \q
```

The lines about `pg_toast` indexes are the rewrite building a new side table for long values; the
line to look for is **`rewriting table "orders_live"`**.

## Adding a column

**A column with a constant default is instant**, `NOT NULL` included. Since PostgreSQL 11 the
default is stored once in the catalogue and handed to every old row when it is read, so no row is
touched; the file kept its name, and the time was a few milliseconds. Before version 11 the same
command rewrote the table, which is why older advice says never to add a column with a default.

**A volatile default rewrites.** `gen_random_uuid()` gives every row a different value, so the
values have to be written into the rows, and the file changed. Two and a half seconds for a million
rows on the recording machine; about forty minutes for a billion, with the table closed throughout.

## Changing a type

**Changing `integer` to `bigint` rewrites**, because a `bigint` is eight bytes and an `integer`
four, so every row changes shape. The lock the session held was `AccessExclusiveLock`, the whole
time.

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
