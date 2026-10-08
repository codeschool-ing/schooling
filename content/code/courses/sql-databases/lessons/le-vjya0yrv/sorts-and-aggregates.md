---
title: Sorting, grouping, and where the memory goes
version: 1
---

Scans and joins produce rows. The nodes above them rearrange rows — order them, group them, cut
them off — and those nodes are where a query's memory is spent. Each one has a line in the plan
that says how it did its work, and that line is the thing to read.

## Sort, and the difference LIMIT makes

The index lesson 9's script built on `placed_at` would answer the first query below without
sorting anything, so to see a sort it goes first. It comes back at the end of this part.

```
shop=# DROP INDEX orders_placed_at_idx;
DROP INDEX

shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at LIMIT 10;
                                                          QUERY PLAN                                                          
------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=39078.64..39078.67 rows=10 width=28) (actual time=136.385..136.402 rows=10 loops=1)
   ->  Sort  (cost=39078.64..41578.64 rows=1000000 width=28) (actual time=136.383..136.384 rows=10 loops=1)
         Sort Key: placed_at
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Seq Scan on orders  (cost=0.00..17469.00 rows=1000000 width=28) (actual time=0.016..70.753 rows=1000000 loops=1)
 Planning Time: 0.378 ms
 Execution Time: 136.442 ms
(7 rows)
```

Three nodes: read everything, sort it, keep ten. `Sort Method: top-N heapsort  Memory: 26kB` is
the interesting line. The sort knew, from the `Limit` above it, that only ten rows would ever be
wanted, so it kept a heap of ten and threw the rest away as it read — a million rows sorted in
twenty-six kilobytes. Lesson 4's `LIMIT` is cheap for exactly this reason.

Take the `LIMIT` off:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at;
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=141052.84..143552.84 rows=1000000 width=28) (actual time=387.046..478.885 rows=1000000 loops=1)
   Sort Key: placed_at
   Sort Method: external merge  Disk: 38584kB
   ->  Seq Scan on orders  (cost=0.00..17469.00 rows=1000000 width=28) (actual time=0.010..66.162 rows=1000000 loops=1)
 Planning Time: 0.074 ms
 Execution Time: 519.615 ms
(6 rows)
```

`Sort Method: external merge  Disk: 38584kB`. The same million rows no longer fit in the memory a
sort is allowed — `work_mem`, 4 MB on this server — so they were written to disk in sorted runs
and merged back. Nearly four times slower than the top-N, and the word to look for is **`Disk`**: a sort
that spills is the most common reason a query that was fine at ten thousand rows is slow at a
million.

Two fixes, in the order to try them. Ask for fewer rows, if the query can — a `LIMIT`, a tighter
`WHERE`. Otherwise give the sort an index to read from:

```
shop=# CREATE INDEX ON orders (placed_at);
CREATE INDEX

shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at LIMIT 10;
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.42..0.98 rows=10 width=28) (actual time=0.037..0.056 rows=10 loops=1)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.42..55855.11 rows=1000000 width=28) (actual time=0.036..0.053 rows=10 loops=1)
 Planning Time: 0.250 ms
 Execution Time: 0.074 ms
(4 rows)
```

With the index on `placed_at` back, there is no `Sort` node at all. The index is already in
order, the scan reads it forwards and stops after ten, and the whole thing is less than a tenth of
a millisecond. Raising `work_mem` is the third option and the one people reach for first; it is a
per-sort allowance, granted to every sort in every connection at once, and a number that fixes one
report can take the server out of memory under load.

## Aggregates: hash or group

```
shop=# EXPLAIN ANALYZE SELECT status, count(*) FROM orders GROUP BY status;
                                                      QUERY PLAN                                                       
-----------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=22469.00..22469.04 rows=4 width=14) (actual time=252.201..252.203 rows=4 loops=1)
   Group Key: status
   Batches: 1  Memory Usage: 24kB
   ->  Seq Scan on orders  (cost=0.00..17469.00 rows=1000000 width=6) (actual time=0.007..74.667 rows=1000000 loops=1)
 Planning Time: 0.130 ms
 Execution Time: 252.272 ms
(6 rows)
```

`GROUP BY status` became a `HashAggregate`: one hash table keyed by the group, one bucket per
status, every row adding to its bucket. `Batches: 1  Memory Usage: 24kB` — four groups, so the
table is tiny. It is the plan when the number of groups is small enough to hold in memory, and
like the hash join, `Batches` above one means it did not fit and spilled.

The other aggregate is `GroupAggregate`, which needs its input sorted by the group key and then
counts each run as it passes. It appears when the input is already sorted — an index on the group
column, or a `Sort` the query needed anyway — and when the planner expects too many groups to hash.
Neither is better; they suit different inputs, and the line beside the node is the check.

## An ORDER BY on top of a GROUP BY

```
shop=# EXPLAIN ANALYZE SELECT city, count(*) FROM customers GROUP BY city ORDER BY city;
                                                         QUERY PLAN                                                          
-----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=2487.27..2487.29 rows=10 width=18) (actual time=26.138..26.141 rows=10 loops=1)
   Sort Key: city
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=2487.00..2487.10 rows=10 width=18) (actual time=26.103..26.107 rows=10 loops=1)
         Group Key: city
         Batches: 1  Memory Usage: 24kB
         ->  Seq Scan on customers  (cost=0.00..1987.00 rows=100000 width=10) (actual time=0.006..7.831 rows=100000 loops=1)
 Planning Time: 0.181 ms
 Execution Time: 26.181 ms
(9 rows)
```

Read from the bottom: scan, hash the groups, then sort the ten groups. That `Sort` is on ten rows
and costs nothing, and it is the right order of operations — grouping first reduces a hundred
thousand rows to ten, and sorting ten is free. A plan that sorted a hundred thousand rows first and
grouped them after would be a `GroupAggregate` over a `Sort`, and that is not wrong either; the
planner priced both and this was cheaper.

## Where a sort came from that you did not write

A `Sort` node with no `ORDER BY` in the query is one of three things: a `Merge Join` needing its
inputs ordered, a `GroupAggregate` needing its groups adjacent, or `DISTINCT` done by sorting.
None of those is a mistake, and each one is a sort the query paid for. When it is large and on
disk, the question is whether an index would have supplied the order — the same fix as above, for
the same reason.

## The pattern

Every node in this section has a line that says **method and memory**: `top-N heapsort`,
`external merge  Disk:`, `Batches:`, `Memory Usage:`. The node name tells you what was done; that
line tells you whether it fit. A plan can be structurally right and still be slow because one of
these lines says `Disk`, and that word is the finding.
