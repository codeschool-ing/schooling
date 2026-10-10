---
title: BUFFERS, and where the pages came from
version: 1
---

Lesson 1 timed one count three times and got 435, 167 and 208 milliseconds: the first run was
**cold**, its pages on the disk, and the others were **warm**. A timing alone cannot say which kind
of run you are looking at. `BUFFERS` can, node by node, because it counts the 8 kB pages each node
touched and says where each one was found.

## Two words, and the wrong reading of one

**`shared hit` is a page that was already in PostgreSQL's own memory**, the 128 MB of shared
buffers lesson 1 looked at. **`shared read` is a page that was not, and had to be asked for from
the operating system.** The tempting reading of `read` is "came from the disk", and it is wrong
often enough to matter: the operating system keeps its own cache of the files, much bigger than
shared buffers on most machines, and a `read` it answers from there costs microseconds. To tell
the two apart you need a timing per read, and one setting gives you that.

## Cold, then warm

Restart the server and drop the operating system's cache, as lesson 1 did, so that nothing is
in memory. Then switch on `track_io_timing` for the session — it makes every read report how long
it took — and run the seller dashboard twice:

```
ana@vm:~$ sudo systemctl restart postgresql
ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
ana@vm:~$ psql market
market=# SET track_io_timing = on;
SET
Time: 2.617 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY 1 ORDER BY 1;
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2287.58..2289.36 rows=79 width=24) (actual time=17.731..17.763 rows=25 loops=1)
   Group Key: (date_trunc('day'::text, placed_at))
   Buffers: shared hit=3 read=380
   I/O Timings: shared read=7.239
   ->  Sort  (cost=2287.58..2287.78 rows=79 width=12) (actual time=17.717..17.726 rows=81 loops=1)
         Sort Key: (date_trunc('day'::text, placed_at))
         Sort Method: quicksort  Memory: 28kB
         Buffers: shared hit=3 read=380
         I/O Timings: shared read=7.239
         ->  Bitmap Heap Scan on orders  (cost=1984.02..2285.09 rows=79 width=12) (actual time=11.561..17.598 rows=81 loops=1)
               Recheck Cond: ((seller_id = 42) AND (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone))
               Heap Blocks: exact=78
               Buffers: shared read=380
               I/O Timings: shared read=7.239
               ->  BitmapAnd  (cost=1984.02..1984.02 rows=79 width=0) (actual time=11.319..11.322 rows=0 loops=1)
                     Buffers: shared read=302
                     I/O Timings: shared read=4.228
                     ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0) (actual time=0.537..0.538 rows=1532 loops=1)
                           Index Cond: (seller_id = 42)
                           Buffers: shared read=4
                           I/O Timings: shared read=0.271
                     ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..1964.12 rows=106093 width=0) (actual time=10.599..10.599 rows=107780 loops=1)
                           Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
                           Buffers: shared read=298
                           I/O Timings: shared read=3.957
 Planning:
   Buffers: shared hit=113 read=29
   I/O Timings: shared read=2.098
 Planning Time: 4.239 ms
 Execution Time: 18.226 ms
(30 rows)

Time: 30.987 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY 1 ORDER BY 1;
                                                                         QUERY PLAN                                                                         
------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2287.58..2289.36 rows=79 width=24) (actual time=3.911..3.927 rows=25 loops=1)
   Group Key: (date_trunc('day'::text, placed_at))
   Buffers: shared hit=380
   ->  Sort  (cost=2287.58..2287.78 rows=79 width=12) (actual time=3.896..3.901 rows=81 loops=1)
         Sort Key: (date_trunc('day'::text, placed_at))
         Sort Method: quicksort  Memory: 28kB
         Buffers: shared hit=380
         ->  Bitmap Heap Scan on orders  (cost=1984.02..2285.09 rows=79 width=12) (actual time=3.773..3.879 rows=81 loops=1)
               Recheck Cond: ((seller_id = 42) AND (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone))
               Heap Blocks: exact=78
               Buffers: shared hit=380
               ->  BitmapAnd  (cost=1984.02..1984.02 rows=79 width=0) (actual time=3.745..3.747 rows=0 loops=1)
                     Buffers: shared hit=302
                     ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0) (actual time=0.237..0.238 rows=1532 loops=1)
                           Index Cond: (seller_id = 42)
                           Buffers: shared hit=4
                     ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..1964.12 rows=106093 width=0) (actual time=3.450..3.450 rows=107780 loops=1)
                           Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
                           Buffers: shared hit=298
 Planning Time: 0.193 ms
 Execution Time: 4.028 ms
(21 rows)

Time: 4.777 ms
```

**The cold run read 380 pages and found 3.** `I/O Timings: shared read=7.239` says those reads
took 7 of the 18 milliseconds the query took to run. **The warm run found all 380** — `shared
hit=380`, no `read` line, no I/O timing — and finished in 4 milliseconds. Same plan, same rows,
same pages; only where the pages were had changed.

Look at the planning lines too. The cold run has a `Planning:` block with its own buffers, 29 of
them read, and `Planning Time: 4.239 ms` against 0.193 the second time. Choosing a plan means
reading the catalogue — which tables exist, which indexes, what the statistics say — and right
after a restart even that comes from the disk. **A first query on a fresh server pays to plan as
well as to run.**

## Buffers add up the tree

Like costs and times, **a node's buffers include its children's**. The `BitmapAnd` has 302: 4 from
the index on `seller_id` and 298 from the index on `placed_at`. The `Bitmap Heap Scan` above it
has 380: those 302 plus the 78 pages of the table it visited, which is the `Heap Blocks: exact=78`
on its line. The 298 pages of December's index entries, again, are most of the work — the same
node the previous section found by subtracting costs, found now by counting pages.

**A page count does not depend on the cache.** The cold and warm runs took 18 and 4 milliseconds
and touched 380 pages each. When you compare two versions of a query, the pages are the
measurement that does not move with whatever ran before, and the time is the one that does. Lesson
24 comes back to this.

## A big scan does not stay in memory

Now the pending count, twice, in the same session:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE status = 'pending';
                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=347.324..351.596 rows=1 loops=1)
   Buffers: shared hit=78 read=16589
   I/O Timings: shared read=876.128
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=347.165..351.589 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=78 read=16589
         I/O Timings: shared read=876.128
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=343.237..343.238 rows=1 loops=3)
               Buffers: shared hit=78 read=16589
               I/O Timings: shared read=876.128
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=342.754..343.118 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
                     Buffers: shared hit=78 read=16589
                     I/O Timings: shared read=876.128
 Planning:
   Buffers: shared hit=11
 Planning Time: 0.142 ms
 Execution Time: 351.639 ms
(20 rows)

Time: 352.488 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE status = 'pending';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=56.371..60.058 rows=1 loops=1)
   Buffers: shared hit=174 read=16493
   I/O Timings: shared read=43.577
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=56.222..60.051 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=174 read=16493
         I/O Timings: shared read=43.577
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=53.744..53.746 rows=1 loops=3)
               Buffers: shared hit=174 read=16493
               I/O Timings: shared read=43.577
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=53.317..53.613 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
                     Buffers: shared hit=174 read=16493
                     I/O Timings: shared read=43.577
 Planning Time: 0.111 ms
 Execution Time: 60.139 ms
(18 rows)

Time: 60.883 ms
```

The first run read 16589 pages, the whole of `orders`, and its I/O took 876 milliseconds. That is
more than the 352 the query took, because three processes were reading at once and their I/O
times are added together.

The second run is the surprise. **It read 16493 pages again** — only 174 were hits — where the
dashboard's second run found every one of its pages. The table is about 130 MB, a little more
than all of shared buffers, but that is not why: PostgreSQL did not even try to keep it. A
sequential scan of a table bigger than a quarter of shared buffers goes through a small ring of
buffers of its own, 256 kB, and reuses it as it goes. One big scan cannot push every other query's
pages out of memory, and the price is that its own pages do not stay.

And yet the second run took 60 milliseconds instead of 352. The I/O line explains it: **the same
16493 reads took 44 milliseconds instead of 876**, because this time the operating system had the
file in its cache. A `read` with a small I/O time is the operating system's memory; a `read` with
a large one is the disk. Without `track_io_timing`, the two runs would have shown the same buffer
counts and very different times, with nothing on the screen to say why.

## Turning it on for good

`SET track_io_timing = on` lasts until `psql` closes, and only a superuser may set it, which `ana`
is. It asks the clock twice for every page read, which on most machines costs too little to
measure. Set in the server's configuration, it also gives `pg_stat_statements` the time its reads
took, next to the counts lesson 2 read. For reading plans, typing it at the top of the session is
enough.

The habit to leave this section with: **`EXPLAIN (ANALYZE, BUFFERS)`, never `ANALYZE` alone.**
Time says how long; buffers say how much work and from where, and only the second explains the
first.
