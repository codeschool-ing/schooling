---
title: The query that ignores the partitioning
version: 1
---

Pruning compares a condition with the partitions' bounds, and the bounds are values of `at`. A
condition the planner cannot turn into a range of `at` gives it nothing to compare, so it keeps
every partition. Nothing warns you: the query returns the right answer, and the only sign is a plan
with all the partitions in it and a time like the unpartitioned table's.

## A function on the key

The same day as section 02, asked the way people often write it, with `date()`:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE date(at) = '2025-11-10';
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=179.334..185.604 rows=1 loops=1)
   ->  Gather (actual time=179.183..185.592 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate (actual time=176.604..176.608 rows=1 loops=3)
               ->  Parallel Append (actual time=136.237..175.780 rows=18565 loops=3)
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_3 (actual time=58.586..58.587 rows=0 loops=3)
                           Filter: (date(at) = '2025-11-10'::date)
                           Rows Removed by Filter: 573903
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_2 (actual time=30.984..88.444 rows=27847 loops=2)
                           Filter: (date(at) = '2025-11-10'::date)
                           Rows Removed by Filter: 805694
                     ->  Parallel Seq Scan on events_2025_10 events_by_month_1 (actual time=171.103..171.103 rows=0 loops=1)
                           Filter: (date(at) = '2025-11-10'::date)
                           Rows Removed by Filter: 1611210
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4 (actual time=0.001..0.002 rows=0 loops=1)
                           Filter: (date(at) = '2025-11-10'::date)
 Planning Time: 0.932 ms
 Execution Time: 185.731 ms
(19 rows)

Time: 187.951 ms
```

The answer is the same 18565 rows per worker, and the plan reads **every partition**: October,
which cannot hold a single row of the 10th of November, was scanned whole and threw away all its
1611210 rows. **185.7 milliseconds**, against 48.3 for the range in section 02, and close to the
216.7 of the unpartitioned table.

**`date(at)` is not `at`.** To prune, the planner would have to know that `date(at) = '2025-11-10'`
means a range of `at`, and it does not reason about what a function does. It is the same reason
lesson 1's `date(placed_at)` could not use the index on `placed_at`, and it has the same fix:
**write the condition on the column itself**, as a range, `at >= '2025-11-10' AND at <
'2025-11-11'`. There is a second, subtler reason in this case: `date()` of a `timestamptz` depends on
the session's time zone, so even a planner that tried could not compare it with fixed bounds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The query&#x27;s condition, at from 2025-11-10 to 2025-11-11, drawn against the four partitions of events_by_month: October, November, December and January 2026. The interval falls inside November only, so November is scanned and the other three are left out of the plan. Below, a condition written as date(at) gives the planner no range to compare, and all four are scanned.\"><text x=\"14\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">range on at</text><text x=\"14\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">at &gt;= '2025-11-10'</text><rect x=\"150\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"215\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">events_2025_10</text><rect x=\"290\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"355\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_11</text><rect x=\"430\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"495\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">events_2025_12</text><rect x=\"570\" y=\"30\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"635\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">events_2026_01</text><text x=\"355\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">one partition scanned, 48.3 ms</text><text x=\"14\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">function on at</text><text x=\"14\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">date(at) = ...</text><rect x=\"150\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"215\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_10</text><rect x=\"290\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"355\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_11</text><rect x=\"430\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"495\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2025_12</text><rect x=\"570\" y=\"120\" width=\"130\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"635\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">events_2026_01</text><text x=\"425\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">all four scanned, 185.7 ms</text></svg>", "caption": "Pruning compares the condition with each partition's bounds. A range on the key leaves one month; the same day written through a function leaves all four."}
```

`extract(month FROM at) = 11` fails the same way, and reads all four:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE extract(month FROM at) = 11;
                                  QUERY PLAN                                   
-------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 2
         ->  Partial Aggregate
               ->  Parallel Append
                     ->  Parallel Seq Scan on events_2025_12 events_by_month_3
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
                     ->  Parallel Seq Scan on events_2025_11 events_by_month_2
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
                     ->  Parallel Seq Scan on events_2025_10 events_by_month_1
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
                     ->  Parallel Seq Scan on events_2026_01 events_by_month_4
                           Filter: (EXTRACT(month FROM at) = '11'::numeric)
(13 rows)

Time: 1.533 ms
```

## A condition on another column

**A query that filters on a column that is not the key cannot prune either**, whatever form it takes:

```
market=# EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE customer_id = 42;
                                              QUERY PLAN                                              
------------------------------------------------------------------------------------------------------
 Aggregate
   ->  Append
         ->  Index Only Scan using events_2025_10_customer_id_idx on events_2025_10 events_by_month_1
               Index Cond: (customer_id = 42)
         ->  Index Only Scan using events_2025_11_customer_id_idx on events_2025_11 events_by_month_2
               Index Cond: (customer_id = 42)
         ->  Index Only Scan using events_2025_12_customer_id_idx on events_2025_12 events_by_month_3
               Index Cond: (customer_id = 42)
         ->  Seq Scan on events_2026_01 events_by_month_4
               Filter: (customer_id = 42)
(10 rows)

Time: 2.102 ms
```

Customer 42's events: an `Append` over all four partitions, an index scan on each month that has rows. Nothing in
`customer_id = 42` says which month the rows are in, so the planner asks every month. With four
partitions and an index on each, that is four small probes and it costs little. It is lesson 17's id
lookup again, and the reason it matters is the next section: the number of probes is the number of
partitions.

## Finding these queries

A query that ignores the partitioning looks normal everywhere except in its plan. Three habits find
them:

- **Read the plan of the important queries on a partitioned table**, and count the partitions under
  the `Append`. A query about one day with every month underneath is the symptom.
- **Look for the key inside a function** in the queries that matter — `date(at)`, `at::date`,
  `extract(… FROM at)`, `to_char(at, …)` — and rewrite them as ranges on the column.
- **Check what the important queries filter on** against the partition key. If the queries that
  matter filter on something else, the partitioning is not helping them, and lesson 17's question
  about the key was answered for the wrong queries.

`pg_stat_statements` from lesson 2 is where the important queries come from: sorted by total time,
the top of the list on a partitioned table is the list of plans to read.
