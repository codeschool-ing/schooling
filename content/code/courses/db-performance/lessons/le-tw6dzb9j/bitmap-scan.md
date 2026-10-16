---
title: The bitmap scan, and the pages it visits once
version: 1
---

The bitmap scan is the planner's answer to the weakness of the last section: too many rows to
fetch one at a time in the index's order, too few to read the whole table. It splits the work in
two nodes, and the split is the whole idea:

1. **`Bitmap Index Scan`** reads the index and, instead of fetching anything, builds a bitmap in
   memory: a mark for every table page that holds a matching row, and which rows on it.
2. **`Bitmap Heap Scan`** then walks the table **in page order**, visiting only the marked pages,
   each one once.

The rows come out in the table's order, not the index's, so a bitmap scan cannot serve an `ORDER
BY` the way an index scan can. What it buys is that no page is read twice and the pages are read
front to back, which is the cheap direction.

## The same hundred customers

Here are the 991 orders of customers 1000 to 1100 again, with bitmap scans allowed — `RESET
enable_bitmapscan;` if your session still has the last section's setting — which is the plan the
planner chooses for them on its own:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.365 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1000 AND 1100;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3453.67..3453.68 rows=1 width=8) (actual time=2.576..2.578 rows=1 loops=1)
   Buffers: shared hit=971
   ->  Bitmap Heap Scan on orders  (cost=19.56..3450.95 rows=1086 width=4) (actual time=0.308..2.494 rows=991 loops=1)
         Recheck Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
         Heap Blocks: exact=967
         Buffers: shared hit=971
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..19.29 rows=1086 width=0) (actual time=0.169..0.169 rows=991 loops=1)
               Index Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
               Buffers: shared hit=4
 Planning:
   Buffers: shared hit=126
 Planning Time: 0.550 ms
 Execution Time: 2.672 ms
(13 rows)

Time: 4.056 ms
```

`Heap Blocks: exact=967`: the bitmap marked 967 pages, and the heap scan visited each of them once,
in order. With the 4 index pages that makes the 971 in `Buffers`, against 994 for the plain index
scan of the same rows. The page count barely moved, because these rows really are on 967 different
pages; what changed is the order, and the planner's price for it: **`3450.95` against `4237.98`**,
because pages read in ascending order are charged closer to sequential reads.

The `Recheck Cond` line is printed on every bitmap heap scan. Whether it actually rechecks
anything depends on what kind of mark each page got, which is the next part.

## Ten percent of the customers

Now ask for the orders of customers 1 to 20000, a tenth of them:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.404 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=23250.24..23250.25 rows=1 width=8) (actual time=185.872..185.875 rows=1 loops=1)
   Buffers: shared hit=1266 read=15630
   ->  Bitmap Heap Scan on orders  (cost=3017.14..22740.80 rows=203777 width=4) (actual time=16.651..160.631 rows=200378 loops=1)
         Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
         Heap Blocks: exact=16667
         Buffers: shared hit=1266 read=15630
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0) (actual time=13.463..13.464 rows=200378 loops=1)
               Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
               Buffers: shared hit=5 read=224
 Planning:
   Buffers: shared hit=122
 Planning Time: 0.781 ms
 Execution Time: 186.112 ms
(13 rows)

Time: 188.068 ms
```

**`Heap Blocks: exact=16667` is every page of `orders`.** Two hundred thousand orders, one tenth of
the table, and because `customer_id` has no correlation with the table's order, there is a matching
row on every single page. The bitmap scan still won — it reads each page once, in order — but it
won by reading the whole table, and the line that tells you so is `Heap Blocks`, not the plan's
name.

## When the bitmap does not fit: lossy pages

The bitmap lives in memory, and the memory it may use is `work_mem`, the same per-operation budget
that sorts and hashes draw on: 4 MB by default. With a mark per row for two hundred thousand rows,
it fitted. Shrink `work_mem` to 64 kB for the session and ask for the plan again:

```
market=# SET work_mem = '64kB';
SET
Time: 1.078 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                             QUERY PLAN                              
---------------------------------------------------------------------
 Aggregate  (cost=47176.44..47176.45 rows=1 width=8)
   ->  Seq Scan on orders  (cost=0.00..46667.00 rows=203777 width=4)
         Filter: ((customer_id >= 1) AND (customer_id <= 20000))
(3 rows)

Time: 1.117 ms
```

The planner abandoned the bitmap and chose a sequential scan, and it had a reason. Switch the
sequential scan off to see the bitmap it refused:

```
market=# SET enable_seqscan = off;
SET
Time: 0.257 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=49365.90..49365.91 rows=1 width=8) (actual time=234.640..234.642 rows=1 loops=1)
   Buffers: shared hit=973 read=15923 written=1
   ->  Bitmap Heap Scan on orders  (cost=3017.14..48856.46 rows=203777 width=4) (actual time=7.339..220.238 rows=200378 loops=1)
         Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
         Rows Removed by Index Recheck: 1729287
         Heap Blocks: exact=635 lossy=16032
         Buffers: shared hit=973 read=15923 written=1
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0) (actual time=7.180..7.181 rows=200378 loops=1)
               Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
               Buffers: shared hit=5 read=224
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.839 ms
 Execution Time: 234.689 ms
(14 rows)

Time: 236.167 ms
```

**`Heap Blocks: exact=635 lossy=16032`.** With no room to remember which rows on each page
matched, the bitmap gave up the detail for most pages and kept one bit per page instead: "something
on this page matches". A lossy page has to be read whole and **every row on it checked again**
against the condition — which is what `Recheck Cond` is for, and what `Rows Removed by Index
Recheck: 1729287` counts. The scan read every page and tested nearly every row, which is a
sequential scan with an index lookup in front of it. The planner priced that at `48856.46` for the
scan against `46667.00` for reading the table plainly, and the sequential scan won.

`work_mem` is not a setting to change on the strength of one plan; `db-administration` lesson 6 is
the arithmetic, because every sort, hash and bitmap of every connection may take that much at
once. What to take from this is how to read it: **`lossy` above zero means the bitmap did not fit
in `work_mem`**, and `Rows Removed by Index Recheck` is what that cost. Put both settings back
with `RESET work_mem;` and `RESET enable_seqscan;`, or close `psql`, which forgets every `SET`.

## Two indexes at once

Lesson 3's seller dashboard showed the other thing only a bitmap can do: combine indexes. Two
`Bitmap Index Scan`s on two different indexes, joined by a `BitmapAnd`, mark only the pages both
conditions hit. An `OR` between two indexed conditions gives a `BitmapOr` the same way. A plain
index scan follows one index; a bitmap can follow several and intersect them before it touches the
table.
