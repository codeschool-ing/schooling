---
title: Constraints without blocking
version: 1
---

Adding a constraint to a table that already has rows means checking every row, and the plain form
does the checking **while it holds `ACCESS EXCLUSIVE`**. PostgreSQL offers a way to split the two:
add the constraint first, for new rows only, in an instant; check the old rows afterwards, under a
lock that lets reads and writes carry on.

## The plain way, for comparison

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# BEGIN;
BEGIN
Time: 0.127 ms

shop=*# ALTER TABLE orders_live ADD CONSTRAINT total_positive CHECK (total_cents > 0);
ALTER TABLE
Time: 159.542 ms

shop=*# SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
        mode         
---------------------
 AccessExclusiveLock
(1 row)

Time: 3.440 ms

shop=*# ROLLBACK;
ROLLBACK
Time: 0.183 ms

shop=# ALTER TABLE orders_live ADD CONSTRAINT total_positive CHECK (total_cents > 0) NOT VALID;
ALTER TABLE
Time: 9.941 ms

shop=# INSERT INTO orders_live (id, customer_id, status, total_cents, created_at) VALUES (0, 1, 'paid', 0, now());
ERROR:  new row for relation "orders_live" violates check constraint "total_positive"
DETAIL:  Failing row contains (0, 1, paid, 0, 2026-10-10 16:40:54.266161-03, null, null, web).
Time: 1.323 ms

shop=# \q
```

The plain `ADD CONSTRAINT` scanned the million rows in a fraction of a second, holding
`AccessExclusiveLock`. On this table that is harmless; on a table a hundred times larger it is a
closed table for as long as the scan takes, plus the queue from the first section.

## `NOT VALID`, then `VALIDATE`

**`NOT VALID` adds the constraint without checking the existing rows.** It took milliseconds, and it
is already enforced: the insert of a zero total was refused by `total_positive`. What it does not
yet promise is anything about the rows that were there before.

**`VALIDATE CONSTRAINT` checks those rows later, under `SHARE UPDATE EXCLUSIVE`**, a lock that
conflicts with other schema changes and with `VACUUM`, and not with `SELECT`, `INSERT`, `UPDATE` or
`DELETE`. Two terminals show it: the first validates inside a transaction and stays there, holding
the lock, and the second writes to the table meanwhile:

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# BEGIN;
BEGIN
Time: 1.244 ms

shop=*# ALTER TABLE orders_live VALIDATE CONSTRAINT total_positive;
ALTER TABLE
Time: 184.590 ms

shop=*# SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
           mode           
--------------------------
 ShareUpdateExclusiveLock
(1 row)

Time: 1.663 ms

shop=*# COMMIT;
COMMIT
Time: 1.960 ms
```

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# UPDATE orders_live SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 177.627 ms
```

**The `UPDATE` went straight through** while the validating transaction held its lock. Its time is
the time of reading a million rows with no index to find id 2, which the next part fixes; it did
not wait for the `COMMIT` in the first terminal. If a row
fails the check, `VALIDATE` stops with an error naming the constraint, nothing is lost, and the
constraint stays in place for new rows while you fix the old ones.

A foreign key works the same way: `ADD CONSTRAINT … FOREIGN KEY … NOT VALID`, then `VALIDATE
CONSTRAINT`.

## A primary key, built beside the table

`orders_live` has no primary key, because `CREATE TABLE … AS` copies none. `ADD PRIMARY KEY` would
build its index under `ACCESS EXCLUSIVE`, and on a large table that takes minutes. The index can be
built first, with **`CREATE UNIQUE INDEX CONCURRENTLY`**, which lets writes continue while it
works; then `ADD CONSTRAINT … PRIMARY KEY USING INDEX` turns that index into the key in a moment.

A primary key also needs its columns `NOT NULL`, and `SET NOT NULL` scans the table under the
strong lock, unless a **valid `CHECK (id IS NOT NULL)` already proves it**. So that check is added
`NOT VALID` and validated first:

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# CREATE UNIQUE INDEX CONCURRENTLY orders_live_id ON orders_live (id);
CREATE INDEX
Time: 1222.423 ms (00:01.222)

shop=# ALTER TABLE orders_live ADD CONSTRAINT id_not_null CHECK (id IS NOT NULL) NOT VALID;
ALTER TABLE
Time: 201.705 ms

shop=# ALTER TABLE orders_live VALIDATE CONSTRAINT id_not_null;
ALTER TABLE
Time: 159.229 ms

shop=# SET client_min_messages = debug1;
SET
Time: 0.225 ms

shop=# ALTER TABLE orders_live ADD CONSTRAINT orders_live_pkey PRIMARY KEY USING INDEX orders_live_id;
DEBUG:  existing constraints on column "orders_live.id" are sufficient to prove that it does not contain nulls
NOTICE:  ALTER TABLE / ADD CONSTRAINT USING INDEX will rename index "orders_live_id" to "orders_live_pkey"
ALTER TABLE
Time: 5.156 ms

shop=# RESET client_min_messages;
RESET
Time: 0.181 ms

shop=# ALTER TABLE orders_live DROP CONSTRAINT id_not_null;
ALTER TABLE
Time: 5.247 ms

shop=# \d orders_live
                         Table "public.orders_live"
   Column    |           Type           | Collation | Nullable |   Default   
-------------+--------------------------+-----------+----------+-------------
 id          | bigint                   |           | not null | 
 customer_id | bigint                   |           |          | 
 status      | character varying(40)    |           |          | 
 total_cents | integer                  |           |          | 
 created_at  | timestamp with time zone |           |          | 
 note        | text                     |           |          | 
 source      | text                     |           |          | 
 channel     | text                     |           | not null | 'web'::text
Indexes:
    "orders_live_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "total_positive" CHECK (total_cents > 0)

shop=# \q
```

The `DEBUG` line is the proof being used: **`existing constraints on column "orders_live.id" are
sufficient to prove that it does not contain nulls`**, so no scan. The `NOTICE` says the index was
renamed to the constraint's name. The temporary check is dropped at the end, since the column is
`NOT NULL` now, and `\d` shows the key.

Two cautions about `CONCURRENTLY`. It cannot run inside a transaction block, so a migration tool
that wraps every step in `BEGIN` has to be told not to. And if it fails halfway, a duplicate value
for instance, it leaves an `INVALID` index behind that has to be dropped; lesson 17 shows what that
looks like and how to clean it up.
