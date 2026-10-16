---
title: Forcing the other plan, only to compare
version: 1
---

When a plan looks wrong, the first question is what the alternative would have cost, and the
planner will not show you a plan it rejected. A family of settings makes it: `enable_seqscan`,
`enable_indexscan`, `enable_bitmapscan` and their relatives for joins and sorts. Switched off for
one session, each one takes an access path out of the planner's reach, and the next `EXPLAIN
ANALYZE` shows the plan it would have chosen without it, run for real.

**They are a way of asking a question, and never a way of fixing a query.** That sentence is the
section, and the rest is why.

## Was the year's sequential scan right?

Every timing below is the **second** run of its statement: run each `EXPLAIN ANALYZE` once, then
again, and read the second, so that both plans are compared warm, as lesson 1 asked. First the plan
the planner chose, then the one it would choose with sequential scans switched off:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01';
                                                                              QUERY PLAN                                                                              
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=31313.85..31313.86 rows=1 width=8) (actual time=104.753..112.030 rows=1 loops=1)
   Buffers: shared hit=16047 read=620
   ->  Gather  (cost=31313.64..31313.85 rows=2 width=8) (actual time=104.603..112.021 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=16047 read=620
         ->  Partial Aggregate  (cost=30313.64..30313.65 rows=1 width=8) (actual time=101.872..101.873 rows=1 loops=3)
               Buffers: shared hit=16047 read=620
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=458656 width=4) (actual time=26.884..75.046 rows=369911 loops=3)
                     Filter: ((placed_at >= '2025-01-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2026-01-01 00:00:00-03'::timestamp with time zone))
                     Rows Removed by Filter: 296756
                     Buffers: shared hit=16047 read=620
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.173 ms
 Execution Time: 112.076 ms
(16 rows)

Time: 113.576 ms

market=# SET enable_seqscan = off;
SET
Time: 0.382 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01';
                                                                                QUERY PLAN                                                                                
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=38998.59..38998.60 rows=1 width=8) (actual time=137.685..145.103 rows=1 loops=1)
   Buffers: shared hit=14932
   ->  Gather  (cost=38998.38..38998.59 rows=2 width=8) (actual time=137.575..145.094 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=14932
         ->  Partial Aggregate  (cost=37998.38..37998.39 rows=1 width=8) (actual time=133.773..133.775 rows=1 loops=3)
               Buffers: shared hit=14932
               ->  Parallel Index Scan using orders_placed_at_idx on orders  (cost=0.43..36851.74 rows=458656 width=4) (actual time=0.040..91.669 rows=369911 loops=3)
                     Index Cond: ((placed_at >= '2025-01-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2026-01-01 00:00:00-03'::timestamp with time zone))
                     Buffers: shared hit=14932
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.124 ms
 Execution Time: 145.142 ms
(15 rows)

Time: 145.687 ms
```

**112 milliseconds for the sequential scan, 145 for the index scan the planner refused.** Its
costs said the same thing in its own units, `31313.86` against `38998.60`. The index scan touched
fewer pages, 14932 against all 16667, and was still slower: following over a million index entries
one at a time is more work than reading pages in order, even when the pages are fewer. The
planner was right, and now you know by how much.

## Was the bitmap scan right?

Twenty thousand customers, with parallel plans off: the bitmap scan the planner chose, then the
same query with bitmap scans switched off:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.524 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=23250.24..23250.25 rows=1 width=8) (actual time=103.550..103.551 rows=1 loops=1)
   Buffers: shared hit=6845 read=10051
   ->  Bitmap Heap Scan on orders  (cost=3017.14..22740.80 rows=203777 width=4) (actual time=11.918..89.257 rows=200378 loops=1)
         Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
         Heap Blocks: exact=16667
         Buffers: shared hit=6845 read=10051
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0) (actual time=9.392..9.393 rows=200378 loops=1)
               Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
               Buffers: shared hit=3 read=226
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.118 ms
 Execution Time: 103.826 ms
(13 rows)

Time: 104.341 ms

market=# SET enable_bitmapscan = off;
SET
Time: 0.156 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=47176.44..47176.45 rows=1 width=8) (actual time=161.253..161.254 rows=1 loops=1)
   Buffers: shared hit=16232 read=435
   ->  Seq Scan on orders  (cost=0.00..46667.00 rows=203777 width=4) (actual time=0.011..145.831 rows=200378 loops=1)
         Filter: ((customer_id >= 1) AND (customer_id <= 20000))
         Rows Removed by Filter: 1799622
         Buffers: shared hit=16232 read=435
 Planning:
   Buffers: shared hit=4
 Planning Time: 0.113 ms
 Execution Time: 161.282 ms
(10 rows)

Time: 161.877 ms
```

With no bitmap available the planner did not fall back to an index scan; it went to a sequential
scan, its next cheapest, and that took **161 milliseconds against the bitmap's 104**. Right again.
Notice what the comparison bought: you learned not only that the bitmap was faster but what the
runner-up was, which is information no amount of staring at the first plan gives.

## It is a penalty, not a ban

Switching a path off does not remove it. It adds a huge number to its cost, so that anything else
wins. When nothing else is possible, the penalised path is chosen anyway:

```
market=# SET enable_seqscan = off;
SET
Time: 0.369 ms

market=# EXPLAIN SELECT * FROM products WHERE title LIKE '%lamp%';
                                   QUERY PLAN                                   
--------------------------------------------------------------------------------
 Seq Scan on products  (cost=10000000000.00..10000001274.00 rows=5051 width=73)
   Filter: (title ~~ '%lamp%'::text)
 JIT:
   Functions: 2
   Options: Inlining true, Optimization true, Expressions true, Deforming true
(5 rows)

Time: 4416.122 ms (00:04.416)
```

There is no index that can answer `LIKE '%lamp%'`, so a sequential scan is the only way to run it,
and the planner chose it with `10000000000.00` added to its cost. That number is the
penalty, printed. The `JIT` lines are a side effect worth seeing: the planner now believes this is
an enormous query and planned to compile it to machine code, a step meant for queries that run for
seconds, on a scan of a 5 MB table. **A plan carrying a cost in the billions is a plan running
under a switched-off setting**, and spotting one in a colleague's session is spotting a forgotten
`SET`.

## Why it is never the fix

The temptation arrives on the day a query is slow and `SET enable_seqscan = off` makes it fast.
Putting that in the application, or worse in the server's configuration, goes wrong three ways:

- **It applies to everything.** The setting does not know which query you meant. Every other
  statement on that connection loses its sequential scans too, including the ones for which a
  sequential scan was right — the year above, and every query that reads most of a table.
- **It hides the reason.** The planner chose badly because one of its inputs was wrong: an estimate,
  a price, a missing index. The setting leaves the wrong input in place, so the next query that
  depends on it goes wrong in a way nobody connects to this one.
- **It does not stay true.** The data grows, the distribution shifts, and the plan the setting
  forces becomes the slow one, with nothing in the plan's own reasoning able to correct it.

So the setting answers a question — "how much would the other plan cost?" — and the answer points
at what to fix. If the forced plan is much faster, compare its estimates with the chosen plan's:
lesson 6 is about the row estimate that was wrong, and lesson 7 about the statistics behind it.
If the forced plan is slower, as both were here, the planner was right and the query needs a
different index or a different question, which is lessons 8 to 10.

Close `psql` when you are done, or `RESET` each setting you changed. Nothing in this lesson changed
a row or the server's configuration, so there is nothing else to undo.
