---
title: What ANALYZE reads, and when it runs by itself
version: 1
---

`ANALYZE orders` took 132 milliseconds on a table of 2.3 million rows. That is far too fast to have
read every row, and it did not. The belief to drop is that `ANALYZE` measures the table. It
**samples** it, and the size of the sample has nothing to do with the size of the table.

## The sample

`VERBOSE` makes `ANALYZE` say what it read:

```
market=# SHOW default_statistics_target;
 default_statistics_target 
---------------------------
 100
(1 row)

Time: 1.149 ms

market=# ANALYZE VERBOSE orders;
INFO:  analyzing "public.orders"
INFO:  "orders": scanned 19167 of 19167 pages, containing 2300000 live rows and 0 dead rows; 30000 rows in sample, 2300000 estimated total rows
ANALYZE
Time: 177.160 ms

market=# ANALYZE VERBOSE events;
INFO:  analyzing "public.events"
INFO:  "events": scanned 30000 of 65432 pages, containing 2292530 live rows and 0 dead rows; 30000 rows in sample, 5000161 estimated total rows
ANALYZE
Time: 237.927 ms
```

Read the two `INFO` lines.

- **`orders`: scanned 19167 of 19167 pages, 30000 rows in sample.** The sample is **30,000 rows**,
  300 times `default_statistics_target`. `orders` has fewer pages than that, so `ANALYZE` visited
  every page and kept a random 30,000 of the 2.3 million rows it found there.
- **`events`: scanned 30000 of 65432 pages, 30000 rows in sample.** A bigger table, and the same
  30,000 rows, now one from each of 30,000 randomly chosen pages. It saw 2,292,530 rows on those
  pages and **estimated** 5,000,161 for the table, from the share of pages it had read. That
  estimate becomes `reltuples`, the row count the planner starts every plan from.

So a table of five million rows and a table of five hundred million get the same 30,000-row sample,
which is why `ANALYZE` is cheap enough to run often and why its results move a little every time:
it is a fresh random sample on each run. Lesson 7 reads what is made from those 30,000 rows, the
common values, the histogram and the distinct counts, and how to give one column a bigger sample.

## When autovacuum runs it

Without the switch section 03 turned off, nobody would have had to type `ANALYZE`. The autovacuum
launcher checks every table about once a minute, and analyses one when enough of it has changed:

```
market=# SELECT relname, n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname IN ('orders', 'events') ORDER BY relname;
 relname | n_mod_since_analyze |         last_analyze          | last_autoanalyze 
---------+---------------------+-------------------------------+------------------
 events  |                   0 | 2026-10-15 22:10:02.506573-03 | 
 orders  |                   0 | 2026-10-15 22:10:01.967236-03 | 
(2 rows)

Time: 3.483 ms

market=# SHOW autovacuum_analyze_threshold;
 autovacuum_analyze_threshold 
------------------------------
 50
(1 row)

Time: 0.312 ms

market=# SHOW autovacuum_analyze_scale_factor;
 autovacuum_analyze_scale_factor 
---------------------------------
 0.1
(1 row)

Time: 0.329 ms

market=# ALTER TABLE orders RESET (autovacuum_enabled);
ALTER TABLE
Time: 118.083 ms
```

The rule is **threshold + scale factor × rows**: 50 + 0.1 × `reltuples`. For `orders` as lesson 3
starts, that is 50 + 0.1 × 2,000,000 = **200,050** changed rows, and the import's 300,000 would have
crossed it. Autoanalyze would have run within about a minute of the import, and `last_autoanalyze`
would show when.

The rule has two consequences worth knowing.

- **A big table waits longer.** At 0.1, a table of 100 million rows is re-analysed after 10 million
  changes. A batch that turns one rare status into a common one can be far below that and still
  change every plan that filters on it. `ALTER TABLE … SET (autovacuum_analyze_scale_factor = 0.01)`
  lowers it for that one table; `db-administration` lesson 14 is the place for the rest of
  autovacuum's settings.
- **The window after a bulk load is real.** Between the `COMMIT` of an import and the next
  autoanalyze, every query plans on the old photograph. A job that loads a large batch and then
  queries it should run `ANALYZE` on the table itself, straight after the load, instead of hoping
  autovacuum gets there first.

The last statement of the block undoes the switch: `RESET (autovacuum_enabled)` puts `orders` back
under autovacuum. Leaving autovacuum off on a table is how its statistics, and its dead rows, go
stale for good.

## Back to where lesson 3 starts

This lesson inserted 300,000 orders and changed a table setting. Close `psql` and put `market` back:

```sh
~/reset-market.sh
```
