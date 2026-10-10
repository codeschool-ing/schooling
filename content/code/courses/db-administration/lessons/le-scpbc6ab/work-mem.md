---
title: work_mem, per operation and per process
version: 1
---

`work_mem` reads like a limit on how much memory a query may use, or a connection. **It is neither: it is the most that one sort or one hash inside one process may use before it
starts writing to temporary files.** A query with three sorts may use three times as much. A
parallel query does that in each of its processes, and a hundred connections may each be running
one. That
is the whole difficulty of sizing it, and the last section of this lesson does the arithmetic.
First, what happens at the limit.

## A sort that does not fit

Sort the million orders by amount, with the default 4 MB, and then with enough room:

```
ana@db:~$ psql shop
shop=# EXPLAIN (ANALYZE, COSTS OFF)
shop-#   SELECT customer_id, total_cents FROM orders ORDER BY total_cents;
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Sort (actual time=357.462..430.820 rows=1000000 loops=1)
   Sort Key: total_cents
   Sort Method: external merge  Disk: 21632kB
   ->  Seq Scan on orders (actual time=2.660..99.928 rows=1000000 loops=1)
 Planning Time: 0.436 ms
 Execution Time: 484.063 ms
(6 rows)

shop=# SET work_mem = '100MB';
SET

shop=# EXPLAIN (ANALYZE, COSTS OFF)
shop-#   SELECT customer_id, total_cents FROM orders ORDER BY total_cents;
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Sort (actual time=281.689..417.494 rows=1000000 loops=1)
   Sort Key: total_cents
   Sort Method: quicksort  Memory: 63639kB
   ->  Seq Scan on orders (actual time=2.064..92.406 rows=1000000 loops=1)
 Planning Time: 0.100 ms
 Execution Time: 450.995 ms
(6 rows)

shop=# \q
```

The line to read is **`Sort Method`**. With 4 MB the sort was an `external merge`: it sorted as
many rows as fitted, wrote them to a temporary file, did that again and again, and merged the
files, 21632 kB of them. With 100 MB it was a `quicksort` entirely in memory, using 63639 kB. The
in-memory version needed about three times the space the files took, because a row being sorted
in memory carries pointers and headers that the files leave out; a sort that spills 20 MB does not
fit in 20 MB of `work_mem`.

`SET` changed the value for this session only, which is how `work_mem` should usually be raised:
for the one job that needs it, not for every connection. `ALTER ROLE reporting SET work_mem =
'256MB'` gives a role its own value from its next connection, the per-role layer from lesson 5,
and a reporting role whose few heavy queries sort millions of rows is the classic case.

The in-memory sort was faster here, and not dramatically. That is this machine again: the
temporary files were written and read back without leaving the page cache. On a server where
they reach the disk, and especially where many sessions spill at once, the gap is wider, and
lesson 19 sets `log_temp_files` so that every spill above a size you choose leaves a line in the
log.

## Two operations, two allowances

A query is a tree of steps, and each sort or hash in the tree has its own `work_mem`:

```
ana@db:~$ psql shop
shop=# EXPLAIN (ANALYZE, COSTS OFF)
shop-#   SELECT customer_id, sum(total_cents) FROM orders
shop-#    GROUP BY customer_id ORDER BY 2 DESC LIMIT 5;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Limit (actual time=286.506..286.527 rows=5 loops=1)
   ->  Sort (actual time=286.504..286.506 rows=5 loops=1)
         Sort Key: (sum(total_cents)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  HashAggregate (actual time=264.105..278.300 rows=50000 loops=1)
               Group Key: customer_id
               Batches: 1  Memory Usage: 4881kB
               ->  Seq Scan on orders (actual time=0.012..88.128 rows=1000000 loops=1)
 Planning Time: 0.506 ms
 Execution Time: 287.907 ms
(10 rows)

shop=# \q
```

This is a new session, so `work_mem` is back to 4 MB. Two steps used memory. The `HashAggregate`
built one entry per customer, 50,000 of them, in **4881 kB, more than `work_mem`, in a single
batch**: a hash gets `work_mem` times `hash_mem_multiplier`, 2, so 8 MB, because a hash that spills
costs more than a sort that does. The `Sort` above it kept only the top five, in 25 kB, and had a
`work_mem` of its own that it barely touched.

A query joining five tables can carry four hashes and a sort, each entitled to its own share, and
a parallel plan gives each of its worker processes the same entitlement again. **The 4 MB is a
ceiling per step, and nothing adds the steps up**: no setting limits the total a query or a
connection takes.
