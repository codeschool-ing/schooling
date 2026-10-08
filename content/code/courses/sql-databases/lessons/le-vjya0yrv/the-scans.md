---
title: The four ways to read a table
version: 1
---

Every plan bottoms out in scans — nodes that read a table and produce rows for everything above
them. PostgreSQL has four, and which one appears is the planner's answer to a single question:
**how many of this table's rows does the query want, and how scattered are they?**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"Four bands, one per scan, each showing an index block on the left and the table on the right as a strip of twenty-two cells, one per page. Index Only Scan opens the index and lights no page at all. Index Scan opens the index and lights three scattered pages. Bitmap Heap Scan opens the index and lights nine pages in two runs, read in page order. Seq Scan leaves the index dark and lights every page. Beside each band: seven rows and none of the pages needed; one row and one random page read; a hundred thousand rows in page order; six hundred thousand rows, every page in order.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Which scan appears is the planner answering one question: how many of the rows does the query want, and how scattered are they?</text><text x=\"180\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">index</text><text x=\"356.0\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">the table, one cell per page</text><text x=\"490\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what makes it the right choice</text><text x=\"14\" y=\"65\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Only Scan</text><rect x=\"150\" y=\"52\" width=\"60\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"65\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" text-anchor=\"middle\" fill=\"var(--phosphor)\">▤</text><rect x=\"236\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"251\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"266\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"281\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"311\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"326\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"341\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"371\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"401\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"416\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"431\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"446\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"461\" y=\"52\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"490\" y=\"65\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">7 rows, no page needed</text><text x=\"14\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Scan</text><rect x=\"150\" y=\"94\" width=\"60\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" text-anchor=\"middle\" fill=\"var(--phosphor)\">▤</text><rect x=\"236\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"251\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"266\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"311\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"326\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"341\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"371\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"401\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"416\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"431\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"446\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"461\" y=\"94\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"490\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 row, one random read</text><text x=\"14\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bitmap Heap Scan</text><rect x=\"150\" y=\"136\" width=\"60\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" text-anchor=\"middle\" fill=\"var(--phosphor)\">▤</text><rect x=\"236\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"251\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"266\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"311\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"326\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"371\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"386\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"401\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"416\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"431\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"446\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"461\" y=\"136\" width=\"14\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"490\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100 000 rows, in page order</text><text x=\"14\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><rect x=\"150\" y=\"178\" width=\"60\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"180\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">·</text><rect x=\"236\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"251\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"266\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"296\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"311\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"326\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"371\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"386\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"401\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"416\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"431\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"446\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"461\" y=\"178\" width=\"14\" height=\"26\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">600 000 rows, all of it</text><rect x=\"14\" y=\"226\" width=\"692\" height=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"14\" y=\"240\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The node name alone is never the finding: a sequential scan is right or wrong depending on the numbers beside it.</text></svg>", "caption": "The strip is the table and each cell is a page. What separates the four is how much of it gets touched and in what order — not which one is faster in the abstract."}
```

## Seq Scan: all of it

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'paid';
                                                   QUERY PLAN                                                   
----------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=600467 width=28) (actual time=0.022..97.607 rows=600048 loops=1)
   Filter: (status = 'paid'::text)
   Rows Removed by Filter: 399952
 Planning Time: 0.508 ms
 Execution Time: 120.157 ms
(5 rows)
```

Six hundred thousand of a million rows, and there is an index on `status` — lesson 9's argument
about selectivity, with the plan to prove it. The planner read the whole table in order, because
following an index to sixty percent of the pages would touch every page anyway, in a worse order.
A sequential scan on a query that returns most of a table is the right plan, and the `Filter`
line on it is not a problem to fix.

It becomes a problem when the `Rows Removed by Filter` number is large and the `rows` number is
small: a million read to keep seven. That shape is a missing index, or one of lesson 9's seven
reasons it is not being used.

## Index Scan: one at a time, in order

```
shop=# EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
                                      QUERY PLAN                                      
--------------------------------------------------------------------------------------
 Index Scan using customers_email_key on customers  (cost=0.42..8.44 rows=1 width=48)
   Index Cond: (email = 'user42@example.com'::text)
(2 rows)
```

Descend the tree, find the entries, fetch each row they point at. This is the plan for a handful of
rows, and its defining property is that the rows come out **in the index's order**. That is why
an `Index Scan` can serve an `ORDER BY` with no sort node above it, as the section on sorts shows.

The cost of an index scan is one random page read per row. That is fine at seven rows and bad at
a hundred thousand, and the planner's answer to a hundred thousand is the fourth kind.

## Index Only Scan: the table is never touched

```
shop=# EXPLAIN ANALYZE SELECT customer_id FROM orders WHERE customer_id = 42;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using orders_customer_id_idx on orders  (cost=0.42..4.62 rows=11 width=4) (actual time=0.055..0.057 rows=7 loops=1)
   Index Cond: (customer_id = 42)
   Heap Fetches: 0
 Planning Time: 0.381 ms
 Execution Time: 0.101 ms
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
---------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=1160.62..9926.71 rows=103767 width=28) (actual time=4.894..71.330 rows=100285 loops=1)
   Recheck Cond: (status = 'cancelled'::text)
   Heap Blocks: exact=7469
   ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..1134.68 rows=103767 width=0) (actual time=3.664..3.665 rows=100285 loops=1)
         Index Cond: (status = 'cancelled'::text)
 Planning Time: 0.425 ms
 Execution Time: 75.559 ms
(7 rows)
```

A hundred thousand rows, ten percent of the table. Too many to fetch one at a time in index
order — that would visit the same pages over and over — and too few to read the whole table. The
bitmap scan is the compromise, and it is always two nodes:

1. **`Bitmap Index Scan`** reads the index and builds a bitmap: one bit per page of the table,
   set where the index says a matching row lives. It returns no rows, which is what `width=0`
   says.
2. **`Bitmap Heap Scan`** walks the table in page order, visiting only the marked pages, and
   re-checks each row against the condition — `Recheck Cond` — because a bitmap knows which page
   and not which row on it.

`Heap Blocks: exact=7469` is every page of the table, which tells you the cancelled orders are
spread through all of it. It still won, at 76 ms against the sequential scan's 120, because the
index did the filtering and the table was read once, sequentially.

The same node appears for seven rows, earlier in this lesson, and for three thousand pending
ones. It is the planner's default whenever more than a few rows are expected, and seeing it is not
a problem: it is the index being used, in the way that suits the count.

## Two conditions, two indexes

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending' AND placed_at >= DATE '2025-09-01';
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=975.09..1500.06 rows=147 width=28) (actual time=5.931..6.645 rows=142 loops=1)
   Recheck Cond: ((status = 'pending'::text) AND (placed_at >= '2025-09-01'::date))
   Heap Blocks: exact=140
   ->  BitmapAnd  (cost=975.09..975.09 rows=147 width=0) (actual time=5.879..5.881 rows=0 loops=1)
         ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..34.17 rows=2900 width=0) (actual time=0.510..0.510 rows=2923 loops=1)
               Index Cond: (status = 'pending'::text)
         ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..940.59 rows=50689 width=0) (actual time=5.176..5.176 rows=51127 loops=1)
               Index Cond: (placed_at >= '2025-09-01'::date)
 Planning Time: 0.483 ms
 Execution Time: 6.747 ms
(10 rows)
```

A `BitmapAnd`: two index scans, one per condition, and the bitmaps combined before the table is
touched. Lesson 9 said PostgreSQL could combine indexes on different columns, and this is what it
looks like. It also shows the cost: the `placed_at` index returned 51 127 entries to intersect
with 2923, and building that bitmap took five of the 6.7 ms. A single composite index on
`(status, placed_at)` would find the 142 rows directly, which is lesson 9's "equality first, then
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
