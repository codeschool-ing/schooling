---
title: A partial index: only the rows anybody asks about
version: 1
---

An index normally holds an entry for every row of its table. A **partial index** holds entries
only for the rows that satisfy a `WHERE` clause written into the index itself. When the queries
that matter all ask about the same small slice of a table, the index can be that slice and no
more. It costs a fraction of the size and a fraction of the upkeep, and it is just as fast for the
queries it was made for.

## The motivating query

`pending-count.sql` from lesson 2 is the operations screen, refreshed by everybody who has it open:

```sql
SELECT count(*) FROM orders WHERE status = 'pending';
```

It came second in lesson 2's tally by total time, and first by mean. Lesson 7 section 03 showed why
it deserves an index: `pending` is 7319 of two million orders, **0.37% of the table**, and with no
index the server reads all two million to count them. Measured alone, four clients for ten seconds:

```
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 10 -f pending-count.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 255.059 ms
tps = 15.682647 (without initial connection time)
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=90.688..99.611 rows=1 loops=1)
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=90.535..99.600 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=85.818..85.819 rows=1 loops=3)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=80.864..85.706 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
 Planning Time: 1.594 ms
 Execution Time: 99.821 ms
(10 rows)

Time: 103.087 ms
```

**255 milliseconds** per count under load, 100 for a single run with the server to itself. Two
parallel workers and the leader each read a third of the table and throw away 664,227 rows to keep
2440.

## The obvious index

```
market=# CREATE INDEX orders_status_idx ON orders (status);
CREATE INDEX
Time: 1241.325 ms (00:01.241)

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=156.43..156.44 rows=1 width=8) (actual time=0.933..0.934 rows=1 loops=1)
   ->  Index Only Scan using orders_status_idx on orders  (cost=0.43..139.93 rows=6600 width=0) (actual time=0.047..0.615 rows=7319 loops=1)
         Index Cond: (status = 'pending'::text)
         Heap Fetches: 0
 Planning Time: 0.894 ms
 Execution Time: 0.995 ms
(6 rows)

Time: 2.773 ms
```

**100 milliseconds to 1.0.** An `Index Only Scan`: the count is answered from the index entries
alone, without visiting the table, and `Heap Fetches: 0` says not one row had to be checked there.
Lesson 10 is about when that happens and when it does not.

That fixes the query, and it is the index most people would stop at. But look at what it holds: an
entry for every one of the two million orders, 1,890,887 of them saying `delivered`, so that the
one question anybody asks, about the 7319 pending ones, can be answered.

## The partial index

```
market=# CREATE INDEX orders_pending_idx ON orders (placed_at) WHERE status = 'pending';
CREATE INDEX
Time: 225.288 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders', 'orders_status_idx', 'orders_pending_idx');
      relname       |  size  
--------------------+--------
 orders             | 130 MB
 orders_status_idx  | 13 MB
 orders_pending_idx | 176 kB
(3 rows)

Time: 1.951 ms
```

**13 MB for the full index, 176 kB for the partial one**, about seventy-five times smaller, and it
took 225 milliseconds to build instead of 1241. The `WHERE status = 'pending'` at the end of the
`CREATE INDEX` is the whole idea: rows that are not pending get no entry.

The indexed column is `placed_at` rather than `status`. Inside the index every row is pending, so
indexing `status` would store the same word 7319 times; `placed_at` is something an operations
screen also wants, "the oldest pending orders first", and the index answers that for free.

With the full index dropped, the count again:

```
market=# DROP INDEX orders_status_idx;
DROP INDEX
Time: 18.428 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=195.78..195.79 rows=1 width=8) (actual time=1.274..1.275 rows=1 loops=1)
   ->  Index Only Scan using orders_pending_idx on orders  (cost=0.28..179.28 rows=6600 width=0) (actual time=0.036..0.904 rows=7319 loops=1)
         Heap Fetches: 0
 Planning Time: 0.496 ms
 Execution Time: 1.327 ms
(5 rows)

Time: 2.562 ms
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 10 -f pending-count.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.735 ms
tps = 5445.029216 (without initial connection time)
```

**1.3 milliseconds**, about the same as with the full index, from a structure seventy-five times smaller.
Under load the count went from **255 milliseconds to 0.7**, and the server answered 5445 of them a
second instead of 16.

The planner used the index although the query never mentions `placed_at`. It can, because the
index's own `WHERE` is the query's `WHERE`: every row the query wants is in the index and every
entry in the index is a row the query wants, so counting the entries is counting the rows. No
`Index Cond` line appears, because there is nothing left to search for.

## When the planner can use it, and when not

A partial index is only usable when the planner can **prove from the query's text** that every row
the query needs is inside the index. Three queries test that:

```
market=# EXPLAIN SELECT id, placed_at FROM orders WHERE status = 'pending' ORDER BY placed_at LIMIT 20;
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Limit  (cost=0.28..1.00 rows=20 width=16)
   ->  Index Scan using orders_pending_idx on orders  (cost=0.28..238.28 rows=6600 width=16)
(2 rows)

Time: 3.089 ms

market=# EXPLAIN SELECT count(*) FROM orders WHERE status = 'shipped';
                                       QUERY PLAN                                        
-----------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28128.39..28128.40 rows=1 width=8)
   ->  Gather  (cost=28128.18..28128.39 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=27128.18..27128.19 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=17805 width=0)
                     Filter: (status = 'shipped'::text)
(6 rows)

Time: 0.918 ms

market=# PREPARE by_status(text) AS SELECT count(*) FROM orders WHERE status = $1;
PREPARE
Time: 0.487 ms

market=# SET plan_cache_mode = force_generic_plan;
SET
Time: 0.385 ms

market=# EXPLAIN EXECUTE by_status('pending');
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28604.71..28604.72 rows=1 width=8)
   ->  Gather  (cost=28604.50..28604.71 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=27604.50..27604.51 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=208333 width=0)
                     Filter: (status = $1)
(6 rows)

Time: 0.655 ms
```

- **`status = 'pending'` with an `ORDER BY placed_at`** uses the index for both: it filters and it
  sorts, and the `Limit` stops after twenty.
- **`status = 'shipped'`** cannot. Shipped rows have no entries in it, and the planner goes back to
  a sequential scan.
- **`status = $1`, prepared with a generic plan**, cannot either, even when executed with
  `'pending'`. A generic plan is made once for any value of `$1`, and for some values the index
  would miss rows, so the planner may not use it. `plan_cache_mode` forced that here; a real
  application gets the same result when a driver prepares the statement and PostgreSQL switches to a
  generic plan after a few executions.

The last one is the trap. `pg_stat_statements` shows the statement as `status = $1` either way,
because it normalises the constants, but what the planner saw is what matters: a literal `'pending'`
in the SQL, or a parameter whose value it saw when planning. If the application binds `status` as a
parameter and the plan cache goes generic, the partial index silently stops being used. The fix is
to write the condition the index needs as a literal in the query, which for a fixed screen like
this one is natural anyway.

## What it costs, and what it saves

Every insert and update of `orders` pays only for rows that are, or were, pending: an order placed
as pending adds an entry, the update that ships it adds none, and `VACUUM` later clears the
entry it left behind. The 1.9 million delivered
orders cost the index nothing. That is the other half of the gain, and lesson 11 puts a number on
what each index charges every write. A partial index is the cheapest index you can give a query,
when the query always asks about the same rows.
