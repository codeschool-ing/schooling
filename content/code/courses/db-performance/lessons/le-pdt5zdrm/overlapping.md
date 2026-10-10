---
title: When one index is the start of another
version: 1
---

A B-tree on `(seller_id, placed_at)` is sorted by `seller_id` first, and by `placed_at` only among
rows with the same seller. So it is also, entry for entry, a B-tree sorted by `seller_id`: every
question an index on `(seller_id)` alone can answer, the two-column index can answer by reading
its first column and ignoring the second. **An index whose columns are the first columns of
another is overlapped by it**, and keeping both pays the write tax twice for one set of reads.

The common belief runs the other way: that the planner needs an index "on exactly the columns of
the `WHERE`", so a query on `seller_id` needs its own. It does not, and `market` can show it.

## Finding the pairs

The query compares every two indexes on the same table and keeps the pairs where the shorter one's
key columns, with their operator classes, are the first key columns of the longer one. It uses
`indnkeyatts`, the number of key columns, rather than all the columns, so the `INCLUDE` columns of
lesson 10 do not count as keys. Expression and partial indexes are left out, because whether one
of those covers another is a question about the expressions and the conditions, and a person
answers it faster than a query:

```sh
cat > ~/overlapping-indexes.sql <<'SQL'
-- overlapping-indexes.sql: pairs where the shorter index's key columns
-- are the first key columns of the longer one, on the same table, with
-- the same operator classes. Expressions and partial indexes are left
-- out: they need reading by eye.
SELECT a.indrelid::regclass AS table,
       a.indexrelid::regclass AS shorter,
       b.indexrelid::regclass AS longer,
       a.indisunique AS shorter_is_unique
FROM pg_index AS a
JOIN pg_index AS b ON b.indrelid = a.indrelid AND b.indexrelid <> a.indexrelid
WHERE a.indnkeyatts < b.indnkeyatts
  AND (b.indkey::int2[])[0:a.indnkeyatts - 1] = (a.indkey::int2[])[0:a.indnkeyatts - 1]
  AND (b.indclass::oid[])[0:a.indnkeyatts - 1] = (a.indclass::oid[])[0:a.indnkeyatts - 1]
  AND a.indexprs IS NULL AND b.indexprs IS NULL
  AND a.indpred IS NULL AND b.indpred IS NULL
ORDER BY 1, 2;
SQL
```

`indkey` and `indclass` are stored as vectors numbered from 0, which is why the slices start at 0.
Run it:

```
ana@vm:~$ psql market -f overlapping-indexes.sql
    table    |         shorter          |           longer            | shorter_is_unique 
-------------+--------------------------+-----------------------------+-------------------
 orders      | orders_placed_at_idx     | orders_placed_at_status_idx | f
 orders      | orders_seller_id_idx     | orders_seller_placed_idx    | f
 order_lines | order_lines_order_id_idx | order_lines_pkey            | f
(3 rows)

Time: 2.717 ms
```

Three pairs, and each one is a different decision.

## Proving the longer one is enough

Before dropping `orders_seller_id_idx`, check that the plan for a seller's orders survives without
it. DDL in PostgreSQL is transactional, so you can drop the index inside a transaction, ask, and
roll the drop back:

```
market=# BEGIN;
BEGIN
Time: 0.283 ms

market=*# DROP INDEX orders_seller_id_idx;
DROP INDEX
Time: 1.763 ms

market=*# EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE seller_id = 42;
                           QUERY PLAN                           
----------------------------------------------------------------
 Aggregate
   ->  Index Only Scan using orders_seller_placed_idx on orders
         Index Cond: (seller_id = 42)
(3 rows)

Time: 1.786 ms

market=*# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1588
(1 row)

Time: 1.245 ms

market=*# ROLLBACK;
ROLLBACK
Time: 0.602 ms
```

With the single-column index gone, the planner went straight to `orders_seller_placed_idx`, read
only its first column, and counted seller 42's 1588 orders in **1.245 ms**, against lesson 1's
0.8 ms on the single-column index on a smaller table. Lesson 3 teaches you to read that plan; what
matters here is the name in it.

**Do this on your own machine, not on a busy server.** `DROP INDEX` inside an open transaction
holds the strongest lock there is on `orders` until the `ROLLBACK`, and every query on the table
waits behind it. Lesson 12 explains why.

## The three decisions

**`orders_seller_id_idx` under `orders_seller_placed_idx`: drop the shorter one.** This is the
usual case. The longer index serves the dashboard, which section 03 of this lesson saw read it
5,750 times, and it serves a plain lookup by seller too, as the plan above shows. The shorter one is
14 MB of pure write tax.

**`order_lines_order_id_idx` under `order_lines_pkey`: drop the shorter one, for a different
reason.** The longer one is the primary key: it cannot be dropped, so it is going to be maintained
whatever you decide, and the 50,844 reads the shorter one took will go to it. The 2025 migration
that added `order_lines_order_id_idx` paid 78 MB and a second index insert per line for an order
page that already had an index.

**`orders_placed_at_idx` under `orders_placed_at_status_idx`: drop the LONGER one.** The rule of
thumb says the shorter goes, and the counters disagree. The composite was built in 2024 for the
monthly report, and when the report ran in section 03, it read the single-column index and left
the composite at zero. The composite is the bigger of the two, 79 MB against 44, and nothing reads
it. The overlap tells you one of a pair is spare; **the counters tell you which one is earning.**

## When the shorter one stays

Two cases make the shorter index worth keeping, and the query's last column is the first of them.

**It is unique.** A unique index on `(email)` with an ordinary index on `(email, name)` is not
redundant: the longer index allows two rows with the same email, and the shorter one is what
forbids it. When `shorter_is_unique` is `t`, drop the longer one if anything, never the shorter.

**It is much smaller and very hot.** The longer index is bigger, so a lookup on its first column
reads more pages to find the same rows. With `(customer_id)` and `(customer_id, notes)`, where
`notes` is a long text column, the two-column index could be many times the size of the one-column
one, and a lookup that runs thousands of times a second would feel it. Measure that case before
deciding; for two narrow columns like `seller_id` and `placed_at`, the plan above is the
measurement.
