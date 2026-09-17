---
title: What to change, in what order
version: 1
---

A plan has been read and the slow node found. What to do about it is a short list, and the order
matters, because the cheap fixes are the ones that make the expensive ones unnecessary.

## 1. Rewrite the query so the index can apply

Before adding anything, check whether the query is refusing an index that exists. Lesson 9's list
of seven reasons is the checklist, and the plan shows which one it is: the column sits in a
`Filter` line with a function or an expression around it.

```
shop=# EXPLAIN ANALYZE SELECT * FROM customers WHERE lower(email) = 'user42@example.com';
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..2602.00 rows=500 width=56) (actual time=0.021..12.183 rows=1 loops=1)
   Filter: (lower(email) = 'user42@example.com'::text)
   Rows Removed by Filter: 99999
 Planning Time: 0.395 ms
 Execution Time: 12.234 ms
(5 rows)
```

There is a unique index on `email`, and the plan is a sequential scan of a hundred thousand rows
to find one. The `Filter` line says why — `lower(email)` — and the fix is either the query, if the
addresses are stored lowercased already, or an index on the expression. Nothing here needed a new
index of the kind the next step adds; it needed the query and the index to name the same thing.

`date(placed_at)`, `price * 1.1`, `phone = 5551234` — each of these is a rewrite, not an index, and
each one also fixes the estimate.

## 2. Add the index the plan is asking for

The plan is asking for one when a scan reads a large table to keep a few rows, or when a nested
loop has a sequential scan on its inner side. It says which column in the `Filter` line.

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19966.00 rows=11 width=28) (actual time=1.779..80.362 rows=13 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999987
 Planning Time: 0.237 ms
 Execution Time: 80.451 ms
(5 rows)
```

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=4.51..47.38 rows=11 width=28) (actual time=0.046..0.111 rows=13 loops=1)
   Recheck Cond: (customer_id = 42)
   Heap Blocks: exact=13
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.031..0.031 rows=13 loops=1)
         Index Cond: (customer_id = 42)
 Planning Time: 0.509 ms
 Execution Time: 0.168 ms
(7 rows)
```

Same query, one index, 80 ms to 0.17. Lesson 9 says how to choose the columns and their order,
and its `maintaining-them` section says to build it `CONCURRENTLY`. Do that, then run the
`EXPLAIN` again — an index the planner declines is a cost with no benefit, and the plan is the only
way to know it was taken.

## 3. Ask for less

Fewer columns, and fewer rows. The section on scans had the version of this that surprises people:

```
shop=# EXPLAIN ANALYZE SELECT customer_id FROM orders WHERE customer_id = 42;
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using orders_customer_id_idx on orders  (cost=0.42..4.62 rows=11 width=4) (actual time=0.021..0.023 rows=13 loops=1)
   Index Cond: (customer_id = 42)
   Heap Fetches: 0
 Planning Time: 0.325 ms
 Execution Time: 0.062 ms
(5 rows)
```

`SELECT customer_id` instead of `SELECT *`, and the scan becomes index-only. The same query with
`*` fetches every row. When the application needs three columns and asks for twenty, it is paying
for the seventeen in pages read, and the plan is where that shows.

Fewer rows is lesson 4's argument with a plan attached. Paging with `OFFSET`:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 500000;
                                                                 QUERY PLAN                                                                 
--------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=27744.94..27746.05 rows=20 width=28) (actual time=125.605..125.610 rows=20 loops=1)
   ->  Index Scan using orders_pkey on orders  (cost=0.42..55489.45 rows=1000000 width=28) (actual time=0.058..111.315 rows=500020 loops=1)
 Planning Time: 0.252 ms
 Execution Time: 125.654 ms
(4 rows)
```

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE id > 500000 ORDER BY id LIMIT 20;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.42..2.18 rows=20 width=28) (actual time=0.043..0.105 rows=20 loops=1)
   ->  Index Scan using orders_pkey on orders  (cost=0.42..43600.09 rows=496810 width=28) (actual time=0.042..0.103 rows=20 loops=1)
         Index Cond: (id > 500000)
 Planning Time: 0.274 ms
 Execution Time: 0.141 ms
(5 rows)
```

Both return twenty rows. The first reads 500 020 through the index to throw away 500 000 — the
`rows=500020` on the scan says so — and the second reads twenty. Keyset paging, `WHERE id > last`,
costs the same on page one and page twenty-five thousand, and `OFFSET` costs more on every page
than the one before.

## 4. Fix the estimate

When the plan's shape is wrong — a nested loop that should have been a hash, a hash built on the
wrong side — and the scans are already using their indexes, the previous section applies.
`ANALYZE`; an expression index, or a rewrite so the column is bare; extended statistics for
columns that move together. The index is not the fix here; the planner would have used it if it
had known.

## 5. Change the shape of the work

Some queries are slow because they do a lot, correctly. A report that joins every order to every
customer and groups by city reads two tables in full and there is no index that changes that.
The options are the ones earlier lessons built: a materialised view refreshed on a schedule
(lesson 7), a summary table maintained as rows arrive, or running the report on a replica so it
competes with nobody. Lesson 11 adds the one that comes from the application side — a query that
is fast and runs a thousand times per page, which no plan will show as slow.

## What not to do

**Do not switch planner settings off in production.** `enable_seqscan = off` and its siblings are
for seeing an alternative plan in a session, as the join section did. Left on, they make the
planner lie to itself about every query on the server, including the ones that were fine.

**Do not add an index for every slow query.** Each one is lesson 9's permanent tax on writes. The
question is always whether the query is worth it — `pg_stat_statements` says how often it runs,
and a report run once a month does not earn an index that a million inserts a day will maintain.

**Do not tune to one execution.** The first run warms the cache; a value at the edge of the
distribution is not the value the query usually gets. Measure twice, with a typical value, and
with `BUFFERS`.

## And then measure again

The number from the first section — the one `pg_stat_statements` or the log gave you — is what
the fix is compared against. A change that reads fewer pages, on the same value, on a warm cache,
is a fix. Anything else is a hypothesis, and the last lesson said what to do with those.
