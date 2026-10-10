---
title: A plan made on yesterday's numbers
version: 1
---

The usual picture of a slow query is a missing index or a query written badly. **A plan can go
wrong with the query, the index and the server all unchanged**, because the table changed and the
summary of it did not. This section makes that happen on purpose, on a copy of `orders`, so that
`shop` itself is never touched.

## A copy, analysed, with the automatic analysis held off

```
shop=# CREATE TABLE orders_copy (LIKE orders INCLUDING ALL);
CREATE TABLE

shop=# ALTER TABLE orders_copy SET (autovacuum_enabled = off);
ALTER TABLE

shop=# CREATE INDEX orders_copy_status ON orders_copy (status);
CREATE INDEX

shop=# INSERT INTO orders_copy (customer_id, status, total_cents, created_at) SELECT customer_id, status, total_cents, created_at FROM orders;
INSERT 0 1000000

shop=# ANALYZE orders_copy;
ANALYZE
```

`LIKE orders INCLUDING ALL` copies the columns, the defaults, the identity and the indexes, and
the `INSERT` copies the million rows. The index on `status` is new: the query below filters on it.
The `ANALYZE` at the end makes this the state of a table that is up to date — the copy as it was
yesterday, summarised.

The `ALTER TABLE` is the line that makes the demonstration possible, and **it is not something to
do to a real table**. Autovacuum, which the next section is about, would notice the change you are
about to make and analyse the table by itself, usually within a minute. That minute is real and it
is where the bad plans live, but it is too short to read a plan in comfort. Switching autovacuum off
for this one table holds the window open for as long as you want.

## Tonight's import

Three hundred thousand orders arrive with a status nobody had used before, `pending`, and a report
counts them per country straight away:

```
shop=# INSERT INTO orders_copy (customer_id, status, total_cents, created_at) SELECT 1 + (i * 7919::bigint) % 50000, 'pending', 1000, timestamptz '2026-09-01 00:00-03' + i * interval '1 second' FROM generate_series(1, 300000) AS i;
INSERT 0 300000

shop=# EXPLAIN ANALYZE SELECT c.country, count(*) FROM orders_copy o JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY c.country;
                                                                        QUERY PLAN                                                                        
----------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=15.96..15.98 rows=1 width=11) (actual time=668.789..704.301 rows=5 loops=1)
   Group Key: c.country
   ->  Sort  (cost=15.96..15.96 rows=1 width=3) (actual time=660.696..685.067 rows=300000 loops=1)
         Sort Key: c.country
         Sort Method: external merge  Disk: 2072kB
         ->  Nested Loop  (cost=0.72..15.95 rows=1 width=3) (actual time=0.094..606.783 rows=300000 loops=1)
               ->  Index Scan using orders_copy_status on orders_copy o  (cost=0.43..7.64 rows=1 width=8) (actual time=0.023..56.604 rows=300000 loops=1)
                     Index Cond: (status = 'pending'::text)
               ->  Index Scan using customers_pkey on customers c  (cost=0.29..8.31 rows=1 width=11) (actual time=0.002..0.002 rows=1 loops=300000)
                     Index Cond: (id = o.customer_id)
 Planning Time: 0.773 ms
 Execution Time: 704.651 ms
(12 rows)
```

Reading plans is `db-performance` lesson 3, and two things in this one are all you need here. The
scan of `orders_copy` says `rows=1` in the estimate and `rows=300000` in what happened. And on the
strength of that one row, the planner chose a **nested loop**: for each order it found, look the
customer up through `customers_pkey`. For one order that is the cheapest plan there is. It ran
300,000 times (`loops=300000`), and the query took 704.651 ms.

The planner did nothing wrong with what it had. Look at what it had:

```
shop=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders_copy' AND attname = 'status';
     most_common_vals     |         most_common_freqs          
--------------------------+------------------------------------
 {paid,shipped,cancelled} | {0.60103333,0.20153333,0.19743334}
(1 row)

shop=# SELECT n_live_tup, n_mod_since_analyze, last_analyze FROM pg_stat_user_tables WHERE relname = 'orders_copy';
 n_live_tup | n_mod_since_analyze |         last_analyze          
------------+---------------------+-------------------------------
    1300000 |              300000 | 2026-10-10 04:26:45.449579-03
(1 row)
```

**The summary still says three values make up the whole table**: 0.60103333 + 0.20153333 +
0.19743334 is 1. A fourth value has no room left in it, so the planner estimates as few rows as it
can and still be an estimate, which is one. It knew the table had grown, because the size on disk
is checked at planning time. What it could not know is what the new rows contain.

`pg_stat_user_tables` is where the server counts what happened to each table, and two of its
columns are the ones an administrator reads here. **`n_mod_since_analyze` is the number of rows
inserted, updated or deleted since the summary was written**: 300,000, nearly a quarter of the
table. `last_analyze` is when that was, and it is the moment before the import.

## One statement

```
shop=# ANALYZE orders_copy;
ANALYZE

shop=# EXPLAIN ANALYZE SELECT c.country, count(*) FROM orders_copy o JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY c.country;
                                                                               QUERY PLAN                                                                               
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=19268.11..19269.37 rows=5 width=11) (actual time=77.028..82.518 rows=5 loops=1)
   Group Key: c.country
   ->  Gather Merge  (cost=19268.11..19269.27 rows=10 width=11) (actual time=77.018..82.507 rows=15 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=18268.08..18268.10 rows=5 width=11) (actual time=73.180..73.185 rows=5 loops=3)
               Sort Key: c.country
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=18267.97..18268.02 rows=5 width=11) (actual time=73.142..73.147 rows=5 loops=3)
                     Group Key: c.country
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Hash Join  (cost=4941.25..17648.67 rows=123861 width=3) (actual time=18.323..60.508 rows=100000 loops=3)
                           Hash Cond: (o.customer_id = c.id)
                           ->  Parallel Bitmap Heap Scan on orders_copy o  (cost=3248.25..15630.51 rows=123861 width=8) (actual time=1.748..13.959 rows=100000 loops=3)
                                 Recheck Cond: (status = 'pending'::text)
                                 Heap Blocks: exact=985
                                 ->  Bitmap Index Scan on orders_copy_status  (cost=0.00..3173.93 rows=297267 width=0) (actual time=4.797..4.798 rows=300000 loops=1)
                                       Index Cond: (status = 'pending'::text)
                           ->  Hash  (cost=1068.00..1068.00 rows=50000 width=11) (actual time=16.265..16.266 rows=50000 loops=3)
                                 Buckets: 65536  Batches: 1  Memory Usage: 2856kB
                                 ->  Seq Scan on customers c  (cost=0.00..1068.00 rows=50000 width=11) (actual time=0.027..7.081 rows=50000 loops=3)
 Planning Time: 0.716 ms
 Execution Time: 82.626 ms
(27 rows)
```

The plan is longer because it is a better one: the bitmap index scan now expects 297,267 rows and finds
300,000, the customers are read once into a hash table (`Hash Join`) instead of looked up 300,000
times, and two parallel workers share the work. **82.626 ms instead of 704.651 ms, for the same
query on the same data**, and the only thing that changed was the summary.

Eight times slower is a mild case. The same mistake in front of a join to a big table, or under a
sort that expected one row and got a million, takes a query from milliseconds to minutes, and
nothing in the query, the index or the log points at the cause.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline. ANALYZE writes the summary: three values, all the rows. Then 300,000 pending rows arrive. From that moment until the next ANALYZE, every plan believes 'pending' is one row, while n_mod_since_analyze counts 300,000 changes. The next ANALYZE, run by you or by autovacuum once 50 rows plus 10% of the table have changed, makes the estimate 297,267 rows.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"250\" y=\"62\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><line x1=\"20\" y1=\"120\" x2=\"700\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"60\" y1=\"110\" x2=\"60\" y2=\"130\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><line x1=\"250\" y1=\"110\" x2=\"250\" y2=\"130\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><line x1=\"580\" y1=\"110\" x2=\"580\" y2=\"130\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"60\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ANALYZE</text><text x=\"66\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the summary is written</text><text x=\"72\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 values, 100% of rows</text><text x=\"250\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">300,000 pending rows arrive</text><text x=\"415\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every plan made in here</text><text x=\"415\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">believes 'pending' is 1 row</text><text x=\"415\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">n_mod_since_analyze: 300,000</text><text x=\"415\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">last_analyze: before the import</text><text x=\"580\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ANALYZE</text><text x=\"580\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">by you, or by autovacuum once</text><text x=\"580\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50 + 10% of the rows changed</text><text x=\"640\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">297,267 rows</text><text x=\"640\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">estimated</text><text x=\"700\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Between a change and the next ANALYZE, the planner works from the old summary. The window is as long as nobody analyses the table."}
```

## What this asks of you

**A job that loads or rewrites a large share of a table runs `ANALYZE` on that table as its last
step**, before anything reads it. Nightly imports, a backfill, a big `DELETE` of old rows, a
migration that rewrites a column: all of them. It costs a fraction of a second on a table like this
one, and `sql-databases` lesson 10 already showed the shortest version of the habit, a load followed
by `ANALYZE`.

It is safe to run on a live table. `ANALYZE` takes a lock that lets reads and writes carry on, and
waits only for things that change the table's structure, a `VACUUM` or another `ANALYZE`. Inside a
transaction it is allowed too, so a load in one transaction can end with the `ANALYZE` that
describes it.

The copy keeps autovacuum switched off for now. The next section switches it back on and watches it
do the same job by itself.
