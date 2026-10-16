---
title: Partitionwise aggregates and joins
version: 1
---

Pruning decides which partitions a query reads. Two more settings decide whether the planner may
treat the partitions as separate pieces of work once it has them: **partitionwise aggregation** and
**partitionwise join**. Both are off by default, and the reason is the previous section's: they let
the planner consider more plans per partition, and planning time grows with that.

## Aggregating partition by partition

Count the events of each kind over the whole table, first with the default and then with the
setting on:

```
market=# SHOW enable_partitionwise_aggregate;
 enable_partitionwise_aggregate 
--------------------------------
 off
(1 row)

Time: 0.455 ms

market=# SELECT kind, count(*) FROM events_by_month GROUP BY kind;
   kind   |  count  
----------+---------
 cart     |  500558
 checkout |  500211
 search   |  999127
 view     | 3000104
(4 rows)

Time: 364.303 ms

market=# SET enable_partitionwise_aggregate = on;
SET
Time: 0.362 ms

market=# EXPLAIN (COSTS OFF) SELECT kind, count(*) FROM events_by_month GROUP BY kind;
                                     QUERY PLAN                                      
-------------------------------------------------------------------------------------
 Finalize GroupAggregate
   Group Key: events_by_month_2.kind
   ->  Sort
         Sort Key: events_by_month_2.kind
         ->  Gather
               Workers Planned: 2
               ->  Parallel Append
                     ->  Partial HashAggregate
                           Group Key: events_by_month_2.kind
                           ->  Parallel Seq Scan on events_2025_12 events_by_month_2
                     ->  Partial HashAggregate
                           Group Key: events_by_month_1.kind
                           ->  Parallel Seq Scan on events_2025_11 events_by_month_1
                     ->  Partial HashAggregate
                           Group Key: events_by_month.kind
                           ->  Parallel Seq Scan on events_2025_10 events_by_month
                     ->  Partial HashAggregate
                           Group Key: events_by_month_3.kind
                           ->  Parallel Seq Scan on events_2026_01 events_by_month_3
(19 rows)

Time: 0.726 ms

market=# SELECT kind, count(*) FROM events_by_month GROUP BY kind;
   kind   |  count  
----------+---------
 cart     |  500558
 checkout |  500211
 search   |  999127
 view     | 3000104
(4 rows)

Time: 292.783 ms
```

With it on, the plan aggregates **each partition on its own**: a `Partial HashAggregate` under the
`Append` for every month, and a `Finalize GroupAggregate` above that combines four small results into
one. Without it, the rows of all four partitions are appended first and aggregated together.

The two runs took **364 and 293 milliseconds**. That difference is real in this transcript and
small enough that lesson 1's noise could swallow much of it, so read it as "not slower" rather than
as a speed-up to count on. The cases where it pays clearly are two: when the `GROUP BY` includes the
partition key, so that each partition's groups are already final and nothing needs combining; and
when each partition's aggregate fits in memory where the whole table's would not.

## Joining partition by partition

A join between two tables **partitioned the same way** — the same key, the same bounds — can be
done as one join per pair of partitions, October with October and November with November, instead
of one join of everything with everything. Joining `events_by_month` with itself on its key, with
the setting on:

```
market=# SET enable_partitionwise_join = on;
SET
Time: 0.399 ms

market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month AS a JOIN events_by_month AS b USING (id, at);
                                 QUERY PLAN                                 
----------------------------------------------------------------------------
 Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Parallel Append
               ->  Parallel Hash Join
                     Hash Cond: ((a_3.id = b_3.id) AND (a_3.at = b_3.at))
                     ->  Parallel Seq Scan on events_2025_12 a_3
                     ->  Parallel Hash
                           ->  Parallel Seq Scan on events_2025_12 b_3
               ->  Parallel Hash Join
                     Hash Cond: ((a_2.id = b_2.id) AND (a_2.at = b_2.at))
                     ->  Parallel Seq Scan on events_2025_11 a_2
                     ->  Parallel Hash
                           ->  Parallel Seq Scan on events_2025_11 b_2
               ->  Parallel Hash Join
                     Hash Cond: ((a_1.id = b_1.id) AND (a_1.at = b_1.at))
                     ->  Parallel Seq Scan on events_2025_10 a_1
                     ->  Parallel Hash
                           ->  Parallel Seq Scan on events_2025_10 b_1
               ->  Nested Loop
                     Join Filter: ((a_4.id = b_4.id) AND (a_4.at = b_4.at))
                     ->  Parallel Seq Scan on events_2026_01 a_4
                     ->  Seq Scan on events_2026_01 b_4
(23 rows)

Time: 21.070 ms
```

Four joins under one `Append`, each pairing a month with the same month, and each building a hash
table of a month instead of three. The empty January pair gets a nested loop, which costs nothing
for two empty tables.

The condition is the whole point, and the daily table shows it. Join `events_by_month` with
`events_by_day` on the same columns, with the setting on, and keep only the lines that say what kind
of join was chosen:

```
ana@vm:~$ psql market -c 'SET enable_partitionwise_join = on' -c 'EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month AS a JOIN events_by_day AS b USING (id, at)' | grep -E 'Join|Append'
         ->  Parallel Hash Join
               ->  Parallel Append
                     ->  Parallel Append
```

**One** `Parallel Hash Join`, with an `Append` of each table's partitions under it: the bounds do not
match, a month against a day, so there are no pairs to join one by one, and the planner joins
everything with everything as it would without the setting.

## When to turn them on

Both settings are per session. They can be switched on for the queries that profit, such as a
report that aggregates by the partition key or a join between two tables cut the same way, and left
off for everything else, where they would only add planning. That is the pattern this lesson and the last
two suggest for partitioning in general: it pays for the queries that are written for it, and
costs a little for every other.

The lesson changed `market` by adding `events_by_day`, and lesson 17's `events_by_month` is not part
of where lesson 19 starts. Close every `psql` on `market`, and put it back:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 9.691 ms
CREATE INDEX
Time: 710.727 ms
```
