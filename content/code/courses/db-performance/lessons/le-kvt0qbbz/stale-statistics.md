---
title: Statistics about yesterday's table
version: 1
---

The statistics are a photograph. `ANALYZE` takes it, and the planner keeps using it until the next
`ANALYZE` takes another. Between the two the table can change completely, and the planner will not
know. Normally autovacuum takes a new photograph once enough rows have changed, which section 05
measures. The gap before it does is where plans go wrong, and the way to watch that gap is to keep
it open on purpose.

## Holding the gap open

A new sales channel sends its backlog in one batch: three hundred thousand pending orders, all
placed on 2 January 2026. Before loading it, switch off autovacuum for `orders`, which also switches
off its automatic `ANALYZE`. A real server would not do this; it is here so that the statistics stay
exactly as stale as the lesson needs, for as long as it needs them:

```
market=# ALTER TABLE orders SET (autovacuum_enabled = off);
ALTER TABLE
Time: 16.426 ms

market=# SELECT setseed(0.6);
 setseed 
---------
 
(1 row)

Time: 0.819 ms

market=# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) SELECT 1 + floor(random() * 200000)::int, 2 + floor(random() * 999)::int, timestamptz '2026-01-02 00:00-03' + random() * interval '1 day', 'pending', 500 + floor(random() * 50000)::int FROM generate_series(1, 300000);
INSERT 0 300000
Time: 6409.504 ms (00:06.410)
```

`setseed` makes `random()` draw the same orders on your machine as on the one these transcripts came
from. The import took six seconds and multiplied the pending orders by forty, from 7319 to
307,319.

## The counters say so

`pg_stat_user_tables` counts changes per table, and `pg_class` holds what the last `ANALYZE` wrote
down. Open a new `psql`, so that the counters of the session that inserted have been sent in, and
ask both:

```
market=# SELECT n_live_tup, n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname = 'orders';
 n_live_tup | n_mod_since_analyze | last_analyze | last_autoanalyze 
------------+---------------------+--------------+------------------
     300000 |              300000 |              | 
(1 row)

Time: 4.125 ms

market=# SELECT reltuples::bigint, relpages, pg_relation_size('orders') / 8192 AS pages_now FROM pg_class WHERE relname = 'orders';
 reltuples | relpages | pages_now 
-----------+----------+-----------
   2000000 |    16667 |     19167
(1 row)

Time: 1.033 ms
```

- **`n_mod_since_analyze: 300000`** is every row inserted, updated or deleted since the statistics
  were taken. This is the number to watch: it says how old the photograph is, in rows.
- **`last_analyze` and `last_autoanalyze` are empty.** The copy of `market` from lesson 2's reset
  script has never been analysed in this database; its statistics came along from `market_base`,
  which the load in lesson 1 analysed.
- **`reltuples` still says 2,000,000 and `relpages` 16,667**, while the table really has **19,167**
  pages now.

## The estimate that comes out

Count the pending orders, with the plan and its actuals:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=47935.90..47935.91 rows=1 width=8) (actual time=192.117..192.119 rows=1 loops=1)
   ->  Seq Scan on orders  (cost=0.00..47916.93 rows=7590 width=0) (actual time=144.194..178.753 rows=307319 loops=1)
         Filter: (status = 'pending'::text)
         Rows Removed by Filter: 1992681
 Planning Time: 0.425 ms
 Execution Time: 192.221 ms
(6 rows)

Time: 193.695 ms
```

**7590 estimated, 307,319 actual**, a ratio of 40. The arithmetic shows exactly which part of the
photograph is stale and which part the planner corrected on its own:

- the **fraction** comes from `pg_stats`: `pending` was 0.0033 of the rows when the sample was
  taken, and lesson 7 section 03 read that number. It has not changed, because nothing has
  re-sampled the column.
- the **row count** does not come from `reltuples` as it stands. The planner reads the table's real
  size in pages at planning time, 19,167, and scales `reltuples` by it: 2,000,000 × 19,167 ÷ 16,667
  is 2.3 million, the right total. 0.0033 × 2.3 million is **7590**.

So the planner knew the table had grown, and believed it had grown with the same mix of rows as
before. That is the usual shape of a stale estimate: the count is roughly right and the
distribution is wrong. An import of a different kind of row, a status that used to be rare and
suddenly is not, a new customer whose orders arrive by the thousand, a date range nobody had asked
about before: each changes what the rows look like without changing what the photograph says.

This query does not care. There is no index on `status`, so it reads the table whatever the
estimate, and 192 milliseconds is what reading the table costs. The next section is a query that
does care.
