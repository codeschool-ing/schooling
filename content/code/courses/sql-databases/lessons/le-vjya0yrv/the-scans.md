---
title: The four ways to read a table
version: 1
---

Every plan bottoms out in scans — nodes that read a table and produce rows for everything above
them. PostgreSQL has four, and which one appears is the planner's answer to a single question:
**how many of this table's rows does the query want, and how scattered are they?**

## Seq Scan: all of it

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'paid';
                                                   QUERY PLAN                                                   
----------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19966.00 rows=599900 width=28) (actual time=0.005..74.665 rows=600336 loops=1)
   Filter: (status = 'paid'::text)
   Rows Removed by Filter: 399664
 Planning Time: 0.342 ms
 Execution Time: 89.843 ms
(5 rows)
```

Six hundred thousand of a million rows, and there is an index on `status` — lesson 9's argument
about selectivity, with the plan to prove it. The planner read the whole table in order, because
following an index to sixty percent of the pages would touch every page anyway, in a worse order.
A sequential scan on a query that returns most of a table is the right plan, and the `Filter`
line on it is not a problem to fix.

It becomes a problem when the `Rows Removed by Filter` number is large and the `rows` number is
small: a million read to keep thirteen. That shape is a missing index, or one of lesson 9's seven
reasons it is not being used.

## Index Scan: one at a time, in order

```
shop=# EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
                                      QUERY PLAN                                      
--------------------------------------------------------------------------------------
 Index Scan using customers_email_key on customers  (cost=0.42..8.44 rows=1 width=56)
   Index Cond: (email = 'user42@example.com'::text)
(2 rows)
```

Descend the tree, find the entries, fetch each row they point at. This is the plan for a handful of
rows, and its defining property is that the rows come out **in the index's order**. That is why
an `Index Scan` can serve an `ORDER BY` with no sort node above it, as the section on sorts shows.

The cost of an index scan is one random page read per row. That is fine at thirteen rows and bad at
a hundred thousand, and the planner's answer to a hundred thousand is the fourth kind.

## Index Only Scan: the table is never touched

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

Lesson 9's covering index, as it appears in a plan. The query asks for `customer_id` and the index
holds `customer_id`, so the rows are not fetched — and `Heap Fetches: 0` says so. Heap is
PostgreSQL's word for the table's own storage, and that line counts the times the index alone was
not enough.

When it is not zero, lesson 9 said why: the visibility map is stale, and `VACUUM` has not caught
up. A plan that says `Index Only Scan` with `Heap Fetches` near the row count is an index-only scan
in name only, and the fix is vacuum rather than anything in the query.

## Bitmap Heap Scan: many rows, fetched in page order

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'cancelled';
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=1096.96..9789.62 rows=98133 width=28) (actual time=4.220..25.108 rows=96942 loops=1)
   Recheck Cond: (status = 'cancelled'::text)
   Heap Blocks: exact=7466
   ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..1072.42 rows=98133 width=0) (actual time=3.215..3.215 rows=96942 loops=1)
         Index Cond: (status = 'cancelled'::text)
 Planning Time: 0.346 ms
 Execution Time: 27.730 ms
(7 rows)
```

Ninety-seven thousand rows, ten percent of the table. Too many to fetch one at a time in index
order — that would visit the same pages over and over — and too few to read the whole table. The
bitmap scan is the compromise, and it is always two nodes:

1. **`Bitmap Index Scan`** reads the index and builds a bitmap: one bit per page of the table,
   set where the index says a matching row lives. It returns no rows, which is what `width=0`
   says.
2. **`Bitmap Heap Scan`** walks the table in page order, visiting only the marked pages, and
   re-checks each row against the condition — `Recheck Cond` — because a bitmap knows which page
   and not which row on it.

`Heap Blocks: exact=7466` is every page of the table, which tells you the cancelled orders are
spread through all of it. It still won, at 27 ms against the sequential scan's 90, because the
index did the filtering and the table was read once, sequentially.

The same node appears for thirteen rows, earlier in this lesson, and for three thousand pending
ones. It is the planner's default whenever more than a few rows are expected, and seeing it is not
a problem: it is the index being used, in the way that suits the count.

## Two conditions, two indexes

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending' AND placed_at >= DATE '2025-06-01';
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=3621.85..5278.39 rows=531 width=28) (actual time=15.411..17.080 rows=562 loops=1)
   Recheck Cond: ((status = 'pending'::text) AND (placed_at >= '2025-06-01'::date))
   Heap Blocks: exact=548
   ->  BitmapAnd  (cost=3621.85..3621.85 rows=531 width=0) (actual time=15.326..15.327 rows=0 loops=1)
         ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..32.92 rows=2733 width=0) (actual time=0.342..0.342 rows=2984 loops=1)
               Index Cond: (status = 'pending'::text)
         ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..3588.41 rows=194131 width=0) (actual time=14.828..14.828 rows=194554 loops=1)
               Index Cond: (placed_at >= '2025-06-01'::date)
 Planning Time: 0.384 ms
 Execution Time: 17.184 ms
(10 rows)
```

A `BitmapAnd`: two index scans, one per condition, and the bitmaps combined before the table is
touched. Lesson 9 said PostgreSQL could combine indexes on different columns, and this is what it
looks like. It also shows the cost: the `placed_at` index returned 194 554 entries to intersect
with 2984, and building that bitmap took most of the 17 ms. A single composite index on
`(status, placed_at)` would find the 562 rows directly, which is lesson 9's "equality first, then
the range".

## Reading a scan

| the node says | the question to ask |
|---|---|
| `Seq Scan` with a large `Rows Removed by Filter` and few rows kept | is there an index, and is it usable? |
| `Seq Scan` keeping most of the table | nothing — this is right |
| `Index Scan` with `loops` in the thousands | is it inside a nested loop that should be a hash join? |
| `Index Only Scan` with `Heap Fetches` near the row count | when did vacuum last run? |
| `Bitmap Heap Scan` with `Heap Blocks` near the table size | is a composite or partial index worth it? |

The point of the table is that **the node name alone is never the finding**. A sequential scan is
right or wrong depending on the numbers beside it, and a plan is read by comparing them.
