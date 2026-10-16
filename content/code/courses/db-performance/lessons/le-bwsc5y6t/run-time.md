---
title: Pruning when the query runs
version: 1
---

Plan-time pruning needs the values in the text of the query. Two ordinary situations do not have
them. A **prepared statement** is planned once with placeholders, `$1`, and executed many times with
different values, which is what most application drivers do. And a condition can compare the key
with something only known while the query runs: a subquery, or a value from the other side of a
join. The planner cannot leave a partition out of a plan whose values it has not seen, so PostgreSQL
prunes a second time, **when the query starts and while it runs**, and the plan shows it differently.

## A prepared statement

`PREPARE` gives a statement a name and placeholders; `EXECUTE` runs it with values. After a few
executions the server may switch to a **generic plan**, one plan for every value, and that is the
case where pruning cannot happen at planning. `plan_cache_mode = force_generic_plan` makes it switch
at once, so the effect is visible on the first run:

```
market=# PREPARE day_count(timestamptz) AS SELECT count(*) FROM events_by_month WHERE at >= $1 AND at < $1 + interval '1 day';
PREPARE
Time: 1.510 ms

market=# SET plan_cache_mode = force_generic_plan;
SET
Time: 0.287 ms

market=# EXPLAIN (ANALYZE, COSTS OFF) EXECUTE day_count('2025-11-10');
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=89.506..95.186 rows=1 loops=1)
   ->  Gather (actual time=89.147..95.137 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=73.862..73.864 rows=1 loops=3)
               ->  Parallel Append (actual time=16.060..72.904 rows=18565 loops=3)
                     Subplans Removed: 3
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_1 (actual time=16.059..71.556 rows=18565 loops=3)
                           Filter: ((at >= $1) AND (at < ($1 + '1 day'::interval)))
                           Rows Removed by Filter: 537129
 Planning Time: 1.763 ms
 Execution Time: 120.182 ms
(12 rows)

Time: 122.699 ms
```

The `Parallel Append` still has only November under it, and above it a line that plan-time pruning
never prints: **`Subplans Removed: 3`**. The plan was built for all four partitions, because at
planning time `$1` could have been any instant; when the statement started with `$1 =
'2025-11-10'`, the executor compared the value with the bounds and dropped three subplans before
reading anything. The filter still says `$1`, which is how you can tell this plan was not made for
this value.

The result is the same work as section 02's plan-time pruning, one month read. The cost is a plan
that is bigger to keep and to start, which with four partitions is nothing, and section 05 measures
what it becomes with hundreds.

## A value from a subquery

The events of the last day the shop received an order. The cut-off is not in the query; it is
whatever `max(placed_at)` on `orders` returns:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= (SELECT max(placed_at) FROM orders) - interval '1 day';
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=103.250..110.046 rows=1 loops=1)
   InitPlan 2 (returns $1)
     ->  Result (actual time=8.367..8.369 rows=1 loops=1)
           InitPlan 1 (returns $0)
             ->  Limit (actual time=0.128..0.129 rows=1 loops=1)
                   ->  Index Only Scan Backward using orders_placed_at_idx on orders (actual time=0.114..0.115 rows=1 loops=1)
                         Index Cond: (placed_at IS NOT NULL)
                         Heap Fetches: 0
   ->  Gather (actual time=103.029..110.029 rows=3 loops=1)
         Workers Planned: 2
         Params Evaluated: $1
         Workers Launched: 2
         ->  Partial Aggregate (actual time=79.986..79.989 rows=1 loops=3)
               ->  Parallel Append (actual time=69.901..78.399 rows=36984 loops=3)
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_3 (actual time=64.543..70.670 rows=36984 loops=3)
                           Filter: (at >= ($1 - '1 day'::interval))
                           Rows Removed by Filter: 536919
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_2 (never executed)
                           Filter: (at >= ($1 - '1 day'::interval))
                     ->  Parallel Seq Scan on events_2025_10 events_by_month_1 (never executed)
                           Filter: (at >= ($1 - '1 day'::interval))
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4 (actual time=0.002..0.002 rows=0 loops=1)
                           Filter: (at >= ($1 - '1 day'::interval))
 Planning Time: 1.228 ms
 Execution Time: 127.075 ms
(25 rows)

Time: 129.854 ms
```

Read the plan from the top. The subquery, `InitPlan`, ran first and returned
its value as `$1`. Then each partition got a different note. December was scanned and found the
rows. **October and November say `(never executed)`**: they were in the plan, the executor checked
`$1` against their bounds when it reached them, and skipped them without opening them. January was
opened and found nothing, in microseconds, because it is empty.

This form prints no `Subplans Removed`, because the value arrived after the executor had started;
the skipped partitions stay in the plan and are marked instead. Both forms are the same idea: the
bounds compared with a value at the last moment it is known.

## When run-time pruning is the one you get

In an application, the prepared case is the common one. A driver that prepares its statements, or
a pool doing it for it as lesson 16's PgBouncer does with `max_prepared_statements`, sends exactly
the query above, many times, with different dates. After five executions the server compares the
cost of its generic plan with the custom plans it has been making, and keeps the generic one if it
is not worse; from then on every execution prunes at run time. The plan you see by typing the query
with a literal date into `psql` is a custom plan, pruned at planning, and it looks different from
what the application runs. Both read one month. `EXPLAIN (ANALYZE)` on the `EXECUTE`, as above, is
the way to see the one the application gets.
