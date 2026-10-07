---
title: Running it for real
version: 1
---

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
```

`EXPLAIN ANALYZE` plans the query, **runs it**, and prints the plan with what actually happened
written beside what was predicted. It is the tool the rest of this lesson uses, and the one word of
caution comes first because it is the one that costs people:

> **It runs the query.** `EXPLAIN ANALYZE DELETE FROM orders` deletes the orders. For anything that
> writes, wrap it: `BEGIN; EXPLAIN ANALYZE …; ROLLBACK;`.

Here is the scan from the last section, run for real, on a server that had just been restarted:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=11 width=28) (actual time=8.803..54.976 rows=7 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999993
 Planning Time: 0.594 ms
 Execution Time: 55.058 ms
(5 rows)
```

## Estimated against actual

Every node now carries two groups in parentheses. The first is the prediction from before; the
second is the measurement:

```
(actual time=8.803..54.976 rows=7 loops=1)
```

**`actual time` is in milliseconds**, two numbers with the same meaning as the two costs: the
time before the first row came out, and the time when the last one did. The first row took nearly
nine milliseconds to appear because that is how far into the table the first order for customer 42
sat; the last came out at fifty-five.

**`rows` is what the node actually returned** — seven, against an estimate of eleven. That is a
good estimate. What counts as a bad one is the subject of its own section, and the habit to build
now is to put the two `rows` side by side on every node you read.

**`loops` is how many times the node ran.** One, here. It is not always one, and when it is not,
every other number on the line is **per loop** — the join section has a node that ran 2923 times
and reports three rows, which is three rows each time. Multiply before you believe a number.

Below the node, `Rows Removed by Filter: 999993` is the cost of a `Filter` line made visible: the
node read a million rows to keep seven. That single line is the whole case for the index, and
the case is made by measurement rather than by argument.

At the bottom, **planning time** and **execution time**. Half a millisecond to plan and
fifty-five to run is the usual shape. A query that spends most of its time planning is rare and it is a
different problem — usually a very wide join with many possible orders.

## Adding the buffers

```
shop=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=11 width=28) (actual time=11.234..69.728 rows=7 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999993
   Buffers: shared hit=32 read=7437
 Planning:
   Buffers: shared hit=103
 Planning Time: 0.455 ms
 Execution Time: 69.807 ms
(8 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19969.00 rows=11 width=28) (actual time=7.137..57.030 rows=7 loops=1)
   Filter: (customer_id = 42)
   Rows Removed by Filter: 999993
   Buffers: shared hit=64 read=7405
 Planning:
   Buffers: shared hit=103
 Planning Time: 0.456 ms
 Execution Time: 57.102 ms
(8 rows)
```

`BUFFERS` adds a line per node saying how many 8 kB pages it touched, and where. **`hit` is a page
that was already in PostgreSQL's memory; `read` is one it had to ask the operating system for**,
and that is the difference between a query that is slow because of work and one that is slow
because of disk. The table is 7469 pages. The first run hit 32 and read 7437, because the server
had just started and its memory was empty.

The second run, straight after, still read 7405, and that is deliberate rather than a fault. A
sequential scan of a table bigger than a quarter of PostgreSQL's memory goes through a small ring
of buffers of its own, so that one large scan cannot push every other query's pages out. The reads
were quick anyway — 70 ms, then 57 — because the operating system keeps its own cache of the file,
and `BUFFERS` cannot see into that one.

That is a general fact about `EXPLAIN ANALYZE` and it is worth stating: **run it twice.** The
first run measures the cache as much as the query. Compare second runs, or compare `BUFFERS`, and
say which you did.

## After the index

```sql
CREATE INDEX ON orders (customer_id);
```

```
shop=# EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=4.51..47.38 rows=11 width=28) (actual time=0.056..0.109 rows=7 loops=1)
   Recheck Cond: (customer_id = 42)
   Heap Blocks: exact=7
   Buffers: shared hit=1 read=9
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.037..0.037 rows=7 loops=1)
         Index Cond: (customer_id = 42)
         Buffers: shared read=3
 Planning:
   Buffers: shared hit=115 read=4
 Planning Time: 0.463 ms
 Execution Time: 0.233 ms
(11 rows)
```

The same query, the same seven rows, and 0.233 ms against 57.102. The plan is a different shape
— a bitmap scan, which the next section explains — and the buffers line went from 7469 pages to
ten. That pair of numbers is what "the index helped" means when it is said precisely: **not
faster, but fewer pages read**, and the time follows from the pages.

This is the loop the last lesson's `maintaining-them` section drew: measure, change, measure again.
`EXPLAIN ANALYZE` before and after, with `BUFFERS`, is the whole of it, and a change that does not
move the pages read has not done what you thought.

## Two things it costs

**Time.** Measuring each node adds overhead, and on a plan with millions of node executions the
measured time can be noticeably above the real one. `EXPLAIN (ANALYZE, TIMING OFF)` keeps the row
counts and drops the clock, and the row counts are usually what you wanted.

**The run itself.** A report that takes four minutes takes four minutes under `EXPLAIN ANALYZE`
too, on the production server, holding whatever lesson 8 said a long statement holds. Plain
`EXPLAIN` is instant and shows the plan; reach for `ANALYZE` when the plan looks fine and the query
is not, because that gap is exactly what only a measurement can close.
