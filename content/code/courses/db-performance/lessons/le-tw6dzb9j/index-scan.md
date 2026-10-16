---
title: The index scan, and the order the rows sit in
version: 1
---

An index scan descends the B-tree to the first entry that matches, walks the entries in the
index's order, and for each one **fetches the row it points at** from the table. Two things make
it fast or slow, and only the first is the one people think of: how many entries match, and how
many different table pages those entries point into.

## One row

The smallest case is a primary key:

```
market=# EXPLAIN ANALYZE SELECT * FROM orders WHERE id = 42;
                                                     QUERY PLAN                                                      
---------------------------------------------------------------------------------------------------------------------
 Index Scan using orders_pkey on orders  (cost=0.43..8.45 rows=1 width=37) (actual time=0.097..0.098 rows=1 loops=1)
   Index Cond: (id = 42)
 Planning Time: 0.600 ms
 Execution Time: 0.178 ms
(4 rows)

Time: 1.987 ms
```

`Index Cond: (id = 42)` and nothing else. A few index pages from the root of the tree down to the
leaf, one table page for the row, and a total cost of `8.45` against the `36667.00` a sequential
scan of the same table costs. **For a handful of rows, nothing is cheaper**, because the work is
proportional to the rows found rather than to the table's size.

The startup cost, `0.43`, is the descent of the tree before the first entry is reached. That is
why an index scan is also the plan a `LIMIT` likes, as lesson 3 showed with the ten earliest
orders: the rows come out in the index's order, one at a time, from the first page touched.

## A day of orders, in 35 pages

Turn parallel plans off for the session, as in lesson 3, so each plan is one tree, and sum the
orders of one day:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.341 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=135.56..135.57 rows=1 width=8) (actual time=1.390..1.391 rows=1 loops=1)
   Buffers: shared read=35
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..127.77 rows=3117 width=4) (actual time=0.093..1.007 rows=2801 loops=1)
         Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-06-02 00:00:00-03'::timestamp with time zone))
         Buffers: shared read=35
 Planning:
   Buffers: shared hit=116
 Planning Time: 0.721 ms
 Execution Time: 1.493 ms
(9 rows)

Time: 3.271 ms
```

**2801 rows from 35 pages.** The index entries for the first of June lead to rows that sit next
to each other in the table, roughly 120 to a page, so the scan fetched a few dozen pages and found
most of a day's orders on each. That is not luck. `market.sql` wrote the orders in the order they
were placed, which is how most tables that record events grow: today's rows go at the end.

## Correlation

PostgreSQL measures that property per column, as part of the statistics `ANALYZE` collects:

```
market=# SELECT attname, correlation FROM pg_stats WHERE tablename = 'orders' AND attname IN ('placed_at', 'customer_id', 'seller_id');
   attname   | correlation  
-------------+--------------
 customer_id | 0.0064027454
 seller_id   |   0.07900135
 placed_at   |            1
(3 rows)

Time: 5.070 ms
```

**`correlation` says how closely the order of a column's values follows the order of the rows on
disk**, from 1 (exactly the same order) through 0 (no relation) to −1 (exactly reversed).
`placed_at` is 1: walking its index walks the table from front to back. `customer_id` is 0.006:
customer 1000's orders and customer 1001's are anywhere in the table, three years apart. The
planner uses this number when it prices an index scan. With a correlation near 1 it charges
the pages fetched as if they were read in sequence; near 0, as random reads at `random_page_cost`,
which is 4 against 1.

To see what a correlation of zero costs, take about a third as many rows as that day — a hundred
customers' orders — and make the planner fetch them through the index. The
second `SET` switches bitmap scans off for the session, for a reason the next section explains;
it is used here only to show the plain index scan:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.366 ms

market=# SET enable_bitmapscan = off;
SET
Time: 0.278 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1000 AND 1100;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=4240.69..4240.70 rows=1 width=8) (actual time=5.743..5.744 rows=1 loops=1)
   Buffers: shared hit=160 read=834
   ->  Index Scan using orders_customer_id_idx on orders  (cost=0.43..4237.98 rows=1086 width=4) (actual time=0.027..5.620 rows=991 loops=1)
         Index Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
         Buffers: shared hit=160 read=834
 Planning:
   Buffers: shared hit=123 read=3
 Planning Time: 0.713 ms
 Execution Time: 5.813 ms
(9 rows)

Time: 7.579 ms
```

**991 rows, and 994 pages touched.** Every row came from a different page: a hundred customers'
orders spread across three years of table, so each fetch landed somewhere new and almost none of
them shared a page with the last. A third of the rows of the day above cost almost thirty times
the pages. The planner priced it at `4237.98`, against `127.77` for the day's 2801 rows, and the
difference between those two costs is almost entirely the correlation.

That is the index scan's weakness. **It fetches in the index's order, not the table's**, so on an
uncorrelated column it visits pages in a random order, and when two matching rows share a page far
apart in the index, it reads that page twice. On a few rows that does not matter. On thousands it
is the slowest plan available, and the next section is the one the planner reaches for instead.

## What an index scan needs

- **few matching rows**, or rows that sit together because the column is correlated with the
  table's order;
- **an index whose leading column is in the condition**, in the form the index is written in —
  lesson 1's `date(placed_at)` was the counter-example;
- a query that benefits from the index's order, which is the case for `ORDER BY … LIMIT`.

Lesson 10 adds the variant that skips the table altogether, the index-only scan, when the index
holds every column the query asks for.
