---
title: The merge join, and the planner caught out
version: 1
---

A merge join needs both inputs **sorted on the join key**. Then it walks them together, like
merging two sorted lists by hand: compare the two current rows, emit a pair when the keys match,
advance whichever side is behind. Each input is read once, in order, and no hash table is built.

The catch is the word *sorted*. If an input has to be sorted first, the sort's startup cost — lesson
3's sort that could hand up nothing until it had seen everything — comes in front of the join. A
merge join earns its place when the order comes free: from an index on the join key, or from a
lower node that already produced the rows in that order.

## Two primary keys, both in order

`orders.id` and `order_lines.order_id` are both the leading column of a primary key, so an index
scan of each hands up rows in join order at no extra cost. Join the first two hundred thousand
orders to their lines and count. The planner's choice comes first, then the plan it would make with
hash joins switched off for the session — lesson 4's way of asking about the plan it rejected. Each
was run once before the run printed, so both are warm:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.465 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.id <= 200000;
                                                                        QUERY PLAN                                                                         
-----------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=145144.82..145144.83 rows=1 width=8) (actual time=1391.081..1391.090 rows=1 loops=1)
   Buffers: shared hit=2767 read=29631, temp read=8879 written=8879
   ->  Hash Join  (cost=9057.96..143883.88 rows=504377 width=0) (actual time=54.065..1367.600 rows=500000 loops=1)
         Hash Cond: (l.order_id = o.id)
         Buffers: shared hit=2767 read=29631, temp read=8879 written=8879
         ->  Seq Scan on order_lines l  (cost=0.00..81847.92 rows=4999992 width=8) (actual time=3.505..399.658 rows=5000000 loops=1)
               Buffers: shared hit=2217 read=29631
         ->  Hash  (cost=5747.07..5747.07 rows=201751 width=8) (actual time=49.344..49.348 rows=200000 loops=1)
               Buckets: 262144  Batches: 2  Memory Usage: 5966kB
               Buffers: shared hit=550, temp written=340
               ->  Index Only Scan using orders_pkey on orders o  (cost=0.43..5747.07 rows=201751 width=8) (actual time=0.042..16.594 rows=200000 loops=1)
                     Index Cond: (id <= 200000)
                     Heap Fetches: 0
                     Buffers: shared hit=550
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.315 ms
 JIT:
   Functions: 10
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.370 ms, Inlining 0.000 ms, Optimization 0.226 ms, Emission 3.363 ms, Total 3.959 ms
 Execution Time: 1392.046 ms
(22 rows)

Time: 1393.115 ms (00:01.393)

market=# SET enable_hashjoin = off;
SET
Time: 0.374 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.id <= 200000;
                                                                            QUERY PLAN                                                                            
------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=177245.60..177245.61 rows=1 width=8) (actual time=170.424..170.426 rows=1 loops=1)
   Buffers: shared hit=2477
   ->  Merge Join  (cost=4.75..175984.65 rows=504377 width=0) (actual time=2.473..143.094 rows=500000 loops=1)
         Merge Cond: (o.id = l.order_id)
         Buffers: shared hit=2477
         ->  Index Only Scan using orders_pkey on orders o  (cost=0.43..5747.07 rows=201751 width=8) (actual time=0.013..20.031 rows=200000 loops=1)
               Index Cond: (id <= 200000)
               Heap Fetches: 0
               Buffers: shared hit=550
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..152204.31 rows=4999992 width=8) (actual time=0.035..48.203 rows=500001 loops=1)
               Heap Fetches: 0
               Buffers: shared hit=1927
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.278 ms
 JIT:
   Functions: 6
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.306 ms, Inlining 0.000 ms, Optimization 0.172 ms, Emission 2.296 ms, Total 2.775 ms
 Execution Time: 170.886 ms
(20 rows)

Time: 171.969 ms
```

The planner chose a hash join and it took **1392 milliseconds**: it read all five million order
lines from the table to keep the half a million belonging to the first two hundred thousand orders,
and it spilled to temporary files on the way. The merge join it rejected took **171**, eight times
less. Its two `Index Only Scan`s handed up rows already in `id` order, and look at the second one:
`rows=500001`. The merge stopped reading `order_lines` as soon as it passed order 200000, one row
beyond the last match, so it touched 2477 pages where the hash join touched more than thirty
thousand.

So the planner was wrong, by a factor of eight, on a plain join with good estimates — 504377 rows
expected, 500000 found. **The estimate was right and the choice was still wrong**, which means
another of its inputs was off.

## Which input

Lesson 3 showed every cost is arithmetic on a price list, and the price that dominates an index
scan is `random_page_cost`: 4, against 1 for a page read in sequence. The merge join's plan is two
index scans; the hash join's is mostly a sequential scan. Ask what the planner would choose if a
page out of order cost about what a page in order does:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.455 ms

market=# SET random_page_cost = 1.1;
SET
Time: 0.469 ms

market=# EXPLAIN SELECT count(*) FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.id <= 200000;
                                                   QUERY PLAN                                                    
-----------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=119671.14..119671.15 rows=1 width=8)
   ->  Merge Join  (cost=3.43..118410.20 rows=504377 width=0)
         Merge Cond: (o.id = l.order_id)
         ->  Index Only Scan using orders_pkey on orders o  (cost=0.43..4140.47 rows=201751 width=8)
               Index Cond: (id <= 200000)
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..96231.41 rows=4999992 width=8)
 JIT:
   Functions: 6
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(9 rows)

Time: 19.341 ms
```

With `random_page_cost` at 1.1 the merge join costs `119671.15`, below the hash join's `145144.83`,
and the planner picks it on its own. On this machine the whole database fits in the operating
system's cache, which lesson 1 measured, so a "random" read is a copy from memory and the default
of 4 overcharges every index scan. That is the input that misled it here.

This is still not a fix to type into a session and forget. The right `random_page_cost` is a fact
about the machine's storage, measured across the workload and set once in the configuration, and
`db-administration` is where that is decided. What this section adds is the method: the forced plan
said the planner was wrong, the estimates said the rows were not the reason, and the price list
said what was. Close `psql`, or `RESET` both settings, before you go on.

## When a merge join is the right answer

- both inputs are already in join order, from an index or from a node below;
- the inputs are large, so a nested loop's lookups would be too many;
- a hash table for either side would be big, or the query also wants the result in that order — a
  merge join's output is sorted on the key, so an `ORDER BY` on it costs nothing extra.

And it is the one of the three that can **stop early on a range**, as it did here, because both
sides arrive in order and the first key past the end of one side ends the join.
