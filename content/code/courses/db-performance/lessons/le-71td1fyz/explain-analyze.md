---
title: EXPLAIN ANALYZE, and multiplying by loops
version: 1
---

`EXPLAIN ANALYZE` plans the query, **runs it**, and prints the plan with a second set of numbers
on every node: what actually happened. `sql-databases` lesson 10 showed the shape. This section is
about the three ways people misread it — a number that is per loop, a time that includes its
children, and a statement that really ran.

## `actual time`, `rows`, `loops`

The order page from lesson 2's workload joins one order's lines to their products. Run it for real
for order 1234567:

```
market=# EXPLAIN ANALYZE SELECT p.title, l.quantity, l.price_cents FROM order_lines AS l JOIN products AS p ON p.id = l.product_id WHERE l.order_id = 1234567;
                                                               QUERY PLAN                                                               
----------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.72..36.91 rows=3 width=28) (actual time=0.091..0.140 rows=4 loops=1)
   ->  Index Scan using order_lines_pkey on order_lines l  (cost=0.43..11.98 rows=3 width=12) (actual time=0.064..0.065 rows=4 loops=1)
         Index Cond: (order_id = 1234567)
   ->  Index Scan using products_pkey on products p  (cost=0.29..8.31 rows=1 width=24) (actual time=0.017..0.017 rows=1 loops=4)
         Index Cond: (id = l.product_id)
 Planning Time: 1.380 ms
 Execution Time: 0.233 ms
(7 rows)

Time: 3.088 ms
```

Each node now has a second bracket. **`actual time=0.064..0.065` is in milliseconds** and mirrors
the cost: when the node handed up its first row, and when it handed up its last. **`rows=4` is
what it really returned**, to put beside the estimate of 3. And **`loops` is how many times the
node ran.**

The scan of `order_lines` ran once and found four lines. The join then looked up each line's
product, so the scan of `products` ran four times: `loops=4`. **Every other number on a line with
`loops` above one is per loop, an average over the runs.** `rows=1` there means one product each
time, four in all; `actual time=0.017..0.017` means seventeen microseconds each time, about 0.07
milliseconds in all. The estimate is per loop too: `rows=1` and `cost=0.29..8.31` are the price of
one lookup.

Four loops is harmless. The same line with `loops=50000` and an innocent-looking `0.017` is
850 milliseconds, and nothing on the line says so until you multiply. **Multiply before you
believe a number** on any node whose `loops` is not 1. Lesson 5 is about the join that produces
those loops and when it is the wrong one.

## Times include the children

The ten cheapest orders, from the previous section, run for real with parallel plans off for
the session:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.442 ms

market=# EXPLAIN ANALYZE SELECT id, placed_at, total_cents FROM orders ORDER BY total_cents LIMIT 10;
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=79886.28..79886.31 rows=10 width=20) (actual time=415.266..415.270 rows=10 loops=1)
   ->  Sort  (cost=79886.28..84886.28 rows=2000000 width=20) (actual time=415.264..415.266 rows=10 loops=1)
         Sort Key: total_cents
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Seq Scan on orders  (cost=0.00..36667.00 rows=2000000 width=20) (actual time=0.069..224.847 rows=2000000 loops=1)
 Planning Time: 0.533 ms
 Execution Time: 415.347 ms
(7 rows)

Time: 417.148 ms
```

The `Seq Scan` handed up its first row at 0.069 ms and its last at 224.847. The `Sort` above it
handed up its **first** row at 415.264. That is the startup cost of the earlier section made
visible: the sort could hand up nothing until the scan had finished, and then spent another
190 milliseconds choosing the ten smallest of two million. `top-N heapsort` says how it did it —
it kept only the ten best seen so far, in 26 kB, instead of sorting everything.

**A node's actual time includes the time of everything under it**, the same way its cost does.
The sort's 415 milliseconds contain the scan's 225. To find where the time went, subtract, as the
previous section did with costs.

## A parallel plan has loops too

Lesson 2's costliest single query counted the pending orders:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=72.965..76.105 rows=1 loops=1)
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=72.830..76.097 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=68.531..68.532 rows=1 loops=3)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=68.112..68.407 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
 Planning Time: 0.536 ms
 Execution Time: 76.222 ms
(10 rows)

Time: 78.012 ms

market=# SELECT count(*) FROM orders WHERE status = 'pending';
 count 
-------
  7319
(1 row)

Time: 61.566 ms
```

`Gather` with `Workers Launched: 2` means the scan was shared between three processes: the one
serving your connection and two helpers. Each of the three ran the `Parallel Seq Scan`, so it says
`loops=3`, and `rows=2440` is the average per process. Multiplied, `2440 × 3` is 7320, against the
7319 the plain count returns; the one row is the rounding of an average. `Rows Removed by Filter:
664227` is per process as well, which makes nearly two million in all.

**Here the rows multiply and the time does not.** The three ran side by side, so 68 milliseconds
each is 68 milliseconds of waiting, not 205. A nested loop's runs happen one after another and its
time multiplies; parallel workers' runs overlap and theirs does not. Lesson 4 is about when the
planner chooses to split a scan this way.

## Planning time and execution time

The two lines at the bottom are the server's own clock. **`Planning Time` is choosing the plan;
`Execution Time` is running it**, from start until the last row was produced. The `Time:` line
under them is `psql`'s, which lesson 1 said includes the trip to the server and back: 78.012
against the server's 76.222 for the pending count.

One more gap between the two is worth knowing about. `EXPLAIN ANALYZE` throws the result away
instead of sending it, so **Execution Time leaves out the cost of shipping the rows to the
client**. A million order lines show the size of it. `\o /dev/null` tells `psql` to throw the
rows away on its side too, so the screen stays readable, and `\o` on its own puts the output back:

```
market=# EXPLAIN ANALYZE SELECT * FROM order_lines WHERE order_id <= 400000;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on order_lines  (cost=23248.37..67625.31 rows=1002315 width=22) (actual time=62.497..195.361 rows=1000000 loops=1)
   Recheck Cond: (order_id <= 400000)
   Heap Blocks: exact=6370
   ->  Bitmap Index Scan on order_lines_pkey  (cost=0.00..22997.79 rows=1002315 width=0) (actual time=61.531..61.532 rows=1000000 loops=1)
         Index Cond: (order_id <= 400000)
 Planning Time: 0.749 ms
 Execution Time: 225.431 ms
(7 rows)

Time: 227.302 ms

market=# \o /dev/null
market=# SELECT * FROM order_lines WHERE order_id <= 400000;
Time: 1137.844 ms (00:01.138)

market=# \o
```

The plan says 225 milliseconds. The same query, with its million rows actually sent to `psql`,
took 1138. For a query that returns a few rows the gap is nothing; for one that returns a lot,
**the application waits for the rows, and the plan does not count them**.

## It runs the statement. All of it.

`EXPLAIN ANALYZE DELETE` deletes. `EXPLAIN ANALYZE UPDATE` updates. The only way to look at the
real plan of a statement that writes, without keeping what it wrote, is to wrap it in a
transaction and roll it back:

```
market=# BEGIN;
BEGIN
Time: 0.413 ms

market=*# EXPLAIN ANALYZE DELETE FROM order_lines WHERE order_id = 7;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Delete on order_lines  (cost=0.43..11.98 rows=0 width=0) (actual time=0.179..0.180 rows=0 loops=1)
   ->  Index Scan using order_lines_pkey on order_lines  (cost=0.43..11.98 rows=3 width=6) (actual time=0.111..0.113 rows=4 loops=1)
         Index Cond: (order_id = 7)
 Planning Time: 0.548 ms
 Execution Time: 0.261 ms
(5 rows)

Time: 1.723 ms

market=*# SELECT count(*) FROM order_lines WHERE order_id = 7;
 count 
-------
     0
(1 row)

Time: 0.953 ms

market=*# ROLLBACK;
ROLLBACK
Time: 0.363 ms

market=# SELECT count(*) FROM order_lines WHERE order_id = 7;
 count 
-------
     4
(1 row)

Time: 0.670 ms
```

Inside the transaction the prompt changes to `market=*#`, which is `psql`'s way of saying a
transaction is open. The delete really ran — the count inside the transaction is 0 — and the
`ROLLBACK` undid it, so the four lines are back. The `Delete` node says `rows=0` because it hands
nothing up; the rows it deleted are the four its child found.

Two things a rollback does not undo, so you are not surprised by them: a sequence that handed out
numbers keeps them used, and the locks the statement took on the rows it changed were real
locks for anybody waiting on them. On a busy server, an `EXPLAIN ANALYZE` of a
large `UPDATE` inside a transaction still blocks the rows it touched until the rollback.
