---
title: Pruning when the query is planned
version: 1
---

Lesson 17 built `events_by_month` and showed that a partitioned table does **more** work for a query
that does not name the partition key. This lesson is the other side: what it does for a query that
does. The mechanism is **partition pruning**, the planner leaving out of the plan every partition
whose bounds cannot contain a matching row, and it happens at two moments. This section is the first
and simplest, when the query is planned.

This lesson starts where lesson 17 left `market`: lesson 3's starting point, plus `events_by_month`
built by lesson 17's file. If you have run `~/reset-market.sh` since, run `psql market -f
events_by_month.sql` again first. Check it is there:

```
market=# \d events_by_month
               Partitioned table "public.events_by_month"
   Column    |           Type           | Collation | Nullable | Default 
-------------+--------------------------+-----------+----------+---------
 id          | bigint                   |           | not null | 
 at          | timestamp with time zone |           | not null | 
 customer_id | integer                  |           |          | 
 kind        | text                     |           | not null | 
 payload     | jsonb                    |           | not null | 
Partition key: RANGE (at)
Indexes:
    "events_by_month_pkey" PRIMARY KEY, btree (id, at)
    "events_by_month_customer_id_idx" btree (customer_id)
Number of partitions: 4 (Use \d+ to list them.)
```

## One day, one partition

Count the events of one day, the 10th of November, and ask for the plan:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= '2025-11-10' AND at < '2025-11-11';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Seq Scan on events_2025_11 events_by_month
                     Filter: ((at >= '2025-11-10 00:00:00-03'::timestamp with time zone) AND (at < '2025-11-11 00:00:00-03'::timestamp with time zone))
(6 rows)

Time: 2.107 ms
```

**One scan, on `events_2025_11`.** The planner compared the condition, `at` from the 10th to the
11th of November, with each partition's bounds, saw that only November's interval overlaps it, and
built a plan with that partition alone. The other three are not in the plan at all, and they are
never opened. Without a condition on `at`, the same count reads all four:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month;
                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Append
                     ->  Parallel Index Only Scan using events_2025_12_customer_id_idx on events_2025_12 events_by_month_3
                     ->  Parallel Index Only Scan using events_2025_11_customer_id_idx on events_2025_11 events_by_month_2
                     ->  Parallel Index Only Scan using events_2025_10_customer_id_idx on events_2025_10 events_by_month_1
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4
(9 rows)

Time: 1.844 ms
```

An `Append`, the node that reads several children one after another, over **four** partitions. And
a condition that spans a boundary keeps exactly the partitions it overlaps:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= '2025-12-20';
                                          QUERY PLAN                                          
----------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Append
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_1
                           Filter: (at >= '2025-12-20 00:00:00-03'::timestamp with time zone)
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_2
                           Filter: (at >= '2025-12-20 00:00:00-03'::timestamp with time zone)
(9 rows)

Time: 0.972 ms
```

From the 20th of December onwards is December and January, so the plan has those two. The bounds
are compared with the **values written in the query**, which is what makes this plan-time pruning:
everything the planner needs is in the text of the statement.

## What it is worth

The same count of one day, on the plain `events` table and on `events_by_month`, with the plans
executed:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events WHERE at >= '2025-11-10' AND at < '2025-11-11';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=212.754..216.575 rows=1 loops=1)
   ->  Gather (actual time=211.446..216.556 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=208.630..208.632 rows=1 loops=3)
               ->  Parallel Seq Scan on events (actual time=86.286..207.487 rows=18565 loops=3)
                     Filter: ((at >= '2025-11-10 00:00:00-03'::timestamp with time zone) AND (at < '2025-11-11 00:00:00-03'::timestamp with time zone))
                     Rows Removed by Filter: 1648102
 Planning Time: 0.407 ms
 Execution Time: 216.684 ms
(10 rows)

Time: 218.378 ms

market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= '2025-11-10' AND at < '2025-11-11';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=45.322..48.230 rows=1 loops=1)
   ->  Gather (actual time=45.152..48.216 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=42.091..42.093 rows=1 loops=3)
               ->  Parallel Seq Scan on events_2025_11 events_by_month (actual time=11.509..41.294 rows=18565 loops=3)
                     Filter: ((at >= '2025-11-10 00:00:00-03'::timestamp with time zone) AND (at < '2025-11-11 00:00:00-03'::timestamp with time zone))
                     Rows Removed by Filter: 537129
 Planning Time: 0.582 ms
 Execution Time: 48.271 ms
(10 rows)

Time: 49.498 ms
```

On `events`, a sequential scan of the whole table: each of its three workers kept 18565 rows on
average and threw away **1648102**. On `events_by_month`, the same kind of scan on **one month**:
537129 thrown away per worker. **216.7 against 48.3 milliseconds**, about four
and a half times faster, for the reason lesson 17 promised: the query names the key, so the server
reads one month in three.

That is the speed-up people expect from partitioning, and now its conditions can be stated. It
needs **a condition on the partition key** that the planner can compare with the bounds, and it pays
in proportion to the share of the table it skips. A query on one day of three months skips two
thirds of the table. A query on the whole period skips nothing and pays the overhead of lesson 17's
id lookup.

It is also worth seeing what it is not. The day's 18565 rows per worker are still found by reading
the **whole month**: pruning chose the partition, and inside it the server did a sequential scan,
because nothing indexes `at`. An index on `at` would find the day's rows directly, with or without
partitions, and lesson 8's BRIN is one that suits a table written in time order. Pruning and an
index answer different questions: which piece of the table to look in, and where inside it.
