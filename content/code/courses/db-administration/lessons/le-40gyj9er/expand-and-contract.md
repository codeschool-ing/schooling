---
title: Expand, backfill, contract
version: 1
---

Some changes cannot be made cheap. `orders_live.total_cents` is an `integer`, it will overflow at
2,147,483,647 cents, and turning it into a `bigint` rewrites the table, as the section before last
measured. **The way round a rewrite is to never ask for one**: add the new column beside the old
one, fill it a little at a time, move over to it, and only then remove the old one. Each step is
short, and each step leaves a table the application can use.

The steps have names. **Expand**: add what is new, alongside what exists. **Backfill**: copy the
old rows into it in batches. **Switch**: make the new one the one in use. **Contract**: remove the
old one. In a real system the application is changed between them too, first to write both columns
and later to read only the new one. Here a trigger plays that part.

## Expand

Save this as `expand.sql`:

```sql
-- expand.sql: a bigint column beside total_cents, kept in step by a trigger.
-- Run it with: psql shop -f expand.sql
SET lock_timeout = '2s';

ALTER TABLE orders_live ADD COLUMN total_cents_new bigint;

CREATE FUNCTION orders_live_sync() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.total_cents_new := NEW.total_cents;
    RETURN NEW;
END $$;

CREATE TRIGGER orders_live_sync
    BEFORE INSERT OR UPDATE ON orders_live
    FOR EACH ROW EXECUTE FUNCTION orders_live_sync();
```

The column has no default, so adding it is the instant kind. The trigger copies `total_cents` into
the new column on every insert and update from now on, so **every row written after this point is
already right**, and only the old rows need the backfill.

```
ana@db:~$ psql shop -f expand.sql
SET
ALTER TABLE
CREATE FUNCTION
CREATE TRIGGER
ana@db:~$ psql shop
shop=# UPDATE orders_live SET total_cents = total_cents + 1 WHERE id = 5 RETURNING id, total_cents, total_cents_new;
 id | total_cents | total_cents_new 
----+-------------+-----------------
  5 |         686 |             686
(1 row)

UPDATE 1

shop=# SELECT id, total_cents, total_cents_new FROM orders_live WHERE id IN (5, 6);
 id | total_cents | total_cents_new 
----+-------------+-----------------
  5 |         686 |             686
  6 |         722 |                
(2 rows)

shop=# \q
```

Row 5 was written and has both values. Row 6 has not been touched yet, and its new column is NULL.

## Backfill, in batches

One `UPDATE orders_live SET total_cents_new = total_cents` would do the backfill in one statement,
and it would be one transaction that locks every row it changes until the end, writes a million new
row versions at once and holds back `VACUUM` the whole time (lesson 14). **Batches keep each
transaction small**: a range of ids, commit, the next range. A procedure can commit between batches,
which a function cannot. Save this as `backfill.sql`:

```sql
-- backfill.sql: copy total_cents into total_cents_new, one range of ids at a time.
-- Run it with: psql shop -f backfill.sql, then CALL backfill_total_cents(100000);
CREATE PROCEDURE backfill_total_cents(batch bigint)
LANGUAGE plpgsql AS $$
DECLARE
    next_id bigint := 0;
    last_id bigint;
BEGIN
    SELECT max(id) INTO last_id FROM orders_live;
    WHILE next_id <= last_id LOOP
        UPDATE orders_live SET total_cents_new = total_cents
         WHERE id >= next_id AND id < next_id + batch
           AND total_cents_new IS NULL;
        COMMIT;
        RAISE NOTICE 'ids below % done', next_id + batch;
        next_id := next_id + batch;
    END LOOP;
END $$;
```

The `id` ranges use the primary key the section before built, so each batch finds its rows through
the index rather than by reading the table. `total_cents_new IS NULL` skips rows the trigger already
filled, and it makes the procedure safe to run again after an interruption.

```
ana@db:~$ psql shop -f backfill.sql
CREATE PROCEDURE
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# CALL backfill_total_cents(100000);
NOTICE:  ids below 100000 done
NOTICE:  ids below 200000 done
NOTICE:  ids below 300000 done
NOTICE:  ids below 400000 done
NOTICE:  ids below 500000 done
NOTICE:  ids below 600000 done
NOTICE:  ids below 700000 done
NOTICE:  ids below 800000 done
NOTICE:  ids below 900000 done
NOTICE:  ids below 1000000 done
NOTICE:  ids below 1100000 done
CALL
Time: 9609.684 ms (00:09.610)

shop=# SELECT count(*) FROM orders_live WHERE total_cents_new IS DISTINCT FROM total_cents;
 count 
-------
     0
(1 row)

Time: 432.123 ms

shop=# \q
```

Eleven batches of up to 100,000 rows, each committed on its own. **The last query is the check**:
no row where the two columns disagree. `IS DISTINCT FROM` treats two NULLs as equal and a NULL
against a number as different, which `<>` does not.

On a busy production table you would pick a smaller batch, pause between batches, and watch
replication lag if there are replicas. The shape is the same.

## Not null, without a scan

The old column has no `NOT NULL`, because `CREATE TABLE … AS` dropped it, but a real `total_cents`
would, and the new column should match. The previous section's trick applies:

```
ana@db:~$ psql shop
shop=# ALTER TABLE orders_live ADD CONSTRAINT total_cents_new_not_null CHECK (total_cents_new IS NOT NULL) NOT VALID;
ALTER TABLE

shop=# ALTER TABLE orders_live VALIDATE CONSTRAINT total_cents_new_not_null;
ALTER TABLE

shop=# SET client_min_messages = debug1;
SET

shop=# ALTER TABLE orders_live ALTER COLUMN total_cents_new SET NOT NULL;
DEBUG:  existing constraints on column "orders_live.total_cents_new" are sufficient to prove that it does not contain nulls
ALTER TABLE

shop=# RESET client_min_messages;
RESET

shop=# ALTER TABLE orders_live DROP CONSTRAINT total_cents_new_not_null;
ALTER TABLE

shop=# \q
```

Every constraint and index on the old column needs the same treatment on the new one before the
switch. Here the old column carries `total_positive`; on a real table that would be one more
`NOT VALID` and `VALIDATE` to do on `total_cents_new` now.

## Switch

The switch renames the columns, so that `total_cents` is the `bigint` from now on, and removes the
trigger, in one short transaction. Save it as `switch.sql`:

```sql
-- switch.sql: make the bigint column the one called total_cents.
-- Run it with: psql shop -f switch.sql
BEGIN;
SET LOCAL lock_timeout = '2s';
ALTER TABLE orders_live RENAME COLUMN total_cents TO total_cents_old;
ALTER TABLE orders_live RENAME COLUMN total_cents_new TO total_cents;
DROP TRIGGER orders_live_sync ON orders_live;
COMMIT;
```

```
ana@db:~$ psql shop -f switch.sql
BEGIN
SET
ALTER TABLE
ALTER TABLE
DROP TRIGGER
COMMIT
```

Renaming a column only edits the catalogue, so the transaction holds `ACCESS EXCLUSIVE` for
milliseconds, and `lock_timeout` keeps it from queueing for longer than two seconds. If it gives up,
nothing has changed, and you run it again.

In a real system the application would already have been changed to read the new column by now,
and renaming would be replaced by that deploy. **The rename works here because nothing else uses
`orders_live`**; on a shared table, renaming a column under a running application breaks every
query that names it.

## Contract

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# ALTER TABLE orders_live DROP COLUMN total_cents_old;
ALTER TABLE
Time: 7.555 ms

shop=# \d orders_live
                         Table "public.orders_live"
   Column    |           Type           | Collation | Nullable |   Default   
-------------+--------------------------+-----------+----------+-------------
 id          | bigint                   |           | not null | 
 customer_id | bigint                   |           |          | 
 status      | character varying(40)    |           |          | 
 created_at  | timestamp with time zone |           |          | 
 note        | text                     |           |          | 
 source      | text                     |           |          | 
 channel     | text                     |           | not null | 'web'::text
 total_cents | bigint                   |           | not null | 
Indexes:
    "orders_live_pkey" PRIMARY KEY, btree (id)

shop=# \q
```

Dropping a column is instant: PostgreSQL marks it dropped in the catalogue and leaves the bytes in
the rows until they are next rewritten. The `total_positive` check went with it, since it named
only that column. `total_cents` is a `bigint`, every value carried across, and at no point was the
table closed for longer than a rename.

## Tidying up

`orders_live` was this lesson's copy, and nothing later reads it:

```
ana@db:~$ psql shop
shop=# DROP TABLE orders_live;
DROP TABLE

shop=# DROP FUNCTION orders_live_sync();
DROP FUNCTION

shop=# DROP PROCEDURE backfill_total_cents(bigint);
DROP PROCEDURE

shop=# \dt
         List of relations
 Schema |   Name    | Type  | Owner 
--------+-----------+-------+-------
 public | customers | table | ana
 public | orders    | table | ana
(2 rows)

shop=# \q
```

`shop` is back to the two tables lesson 4 made, untouched.
