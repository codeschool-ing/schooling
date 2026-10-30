---
title: Pruning, measured on DuckDB
version: 1
---

**Pruning is the engine deciding, before it reads anything, which partitions a filter rules out.**
BigQuery does it from the table's metadata, and DuckDB does it from the names of the folders, and
for the folders of lesson 13 the two decisions are the same idea. DuckDB has the advantage of
printing it. With `ask.py` from lesson 13, a question that starts with `EXPLAIN` prints the plan, and
the plan of a query for one day says how many of the sixty files it will open:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt = DATE '2026-09-29'"
┌───────────────────────────┐
│    UNGROUPED_AGGREGATE    │
│    ────────────────────   │
│    Aggregates: sum(#0)    │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         PROJECTION        │
│    ────────────────────   │
│        total_cents        │
│                           │
│        ~25,373 rows       │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│        READ_PARQUET       │
│    ────────────────────   │
│         Function:         │
│        READ_PARQUET       │
│                           │
│        Projections:       │
│        total_cents        │
│                           │
│       File Filters:       │
│ (dt = '2026-09-29'::DATE) │
│                           │
│    Scanning Files: 1/60   │
│                           │
│        ~25,373 rows       │
└───────────────────────────┘
```

**`Scanning Files: 1/60` is the pruning, and `File Filters` is what did it.** The plan is read from
the bottom up, which lesson 16 explains. The read step lists the one column it projects,
`total_cents`, and the filter on `dt` that it applied to the folder names before opening anything.
DuckDB's estimate of the rows, about 25,373, is a guess made before reading; the day holds 16,359,
and the guess does not matter, because the files it skipped it never opens.

## Filters that prune, and filters that do not

**A filter prunes when the engine can compare it with the partition values without reading a row.**
Five filters, each printing the line `Scanning Files` when the plan has one, or `every file` when it
has none:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-07'" | grep 'Scanning Files' || echo 'every file'
│    Scanning Files: 7/60   │
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE created_at >= TIMESTAMP '2026-09-29 00:00:00-03'" | grep 'Scanning Files' || echo 'every file'
every file
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt + INTERVAL 1 DAY = DATE '2026-09-30'" | grep 'Scanning Files' || echo 'every file'
every file
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt = (SELECT max(dt) FROM orders)" | grep 'Scanning Files' || echo 'every file'
every file
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE strftime(dt, '%Y-%m') = '2026-09'" | grep 'Scanning Files' || echo 'every file'
│   Scanning Files: 29/60   │
```

**A range on `dt` pruned to seven files**, the first week of September. **A filter on `created_at`
pruned nothing**: it holds the same day as `dt`, and DuckDB has no way to know that, because the
folders are named by `dt`. BigQuery behaves the same way. A table partitioned by one column is pruned
only by a filter on that column, whatever the other columns happen to mean.

**`dt + INTERVAL 1 DAY` pruned nothing**, because the column is inside an expression. Google's
documentation says the same of BigQuery in its advice on querying partitioned tables: keep the
partitioning column alone on one side of the comparison, and write `dt = DATE '2026-09-29'` rather
than arithmetic on `dt`. **The subquery pruned nothing at planning time** either, because the day it
asks for is only known once `max(dt)` has been read. Google's documentation gives this very case as
one that does not limit the partitions scanned: a filter has to be a constant expression for the
pruning to happen before the query reads.

**`strftime(dt, '%Y-%m')` is where the two engines part.** DuckDB evaluated the function on each
folder's value and kept the 29 September files. Nothing in Google's documentation promises BigQuery
does the same with a function wrapped round the partitioning column, and its advice points the other
way. So the rule this course takes from both is the safe one: **compare the partitioning column, bare,
with constants**, and let `dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-30'` say what
`strftime` was trying to.

## What pruning saves, in BigQuery's bytes

A query that adds up `total_cents` for a week references two columns, `dt` and `total_cents`, both 8
bytes a row. DuckDB counts the rows, whole and for the week, and lesson 14's `ondemand.py` prices
them. Quitanda's table is so small that both would cost the 10 MB minimum, so the bytes are multiplied
by a thousand first, as for a company a thousand times its size:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT 16 * count(*) AS whole_table, 16 * count(*) FILTER (WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-07') AS one_week FROM orders"
┌─────────────┬──────────┐
│ whole_table │ one_week │
│    int64    │  int64   │
├─────────────┼──────────┤
│    19921888 │  2339968 │
└─────────────┴──────────┘

ana@laptop:~/gcp$ python3 ondemand.py 19921888000; python3 ondemand.py 2339968000
read  19,921,888,000 bytes   billed  19,921,895,424 bytes   0.203837 USD
read   2,339,968,000 bytes   billed   2,340,421,632 bytes   0.023947 USD
```

**At a thousand times the size, the week costs 0.0239 USD against 0.2038 for the whole table**, an
eighth, because seven of the sixty days is about an eighth. The saving is exactly the share of
partitions pruned, and it grows with the history: against three years of days instead of sixty, the
same week would cost about a hundred and fiftieth of the unpartitioned scan.

## Requiring the filter

**`require_partition_filter` makes BigQuery refuse a query on the table that has no filter on the
partitioning column.** It is an option of the table, set in its DDL or later with
`ALTER TABLE quitanda.orders SET OPTIONS (require_partition_filter = TRUE)`. A query such as
`SELECT sum(total_cents) FROM quitanda.orders` then fails with an error saying it cannot query the
table without a filter on `dt`, and costs nothing, because a query that fails is not billed.

**It is the cheapest guardrail in this course, and it guards one particular mistake**: the analyst who
forgets the date, and the dashboard built by somebody who did not know the table was large. It does
not check that the filter prunes much: `WHERE dt > DATE '2000-01-01'` satisfies it and reads every
partition. Nor does it catch the filter on `created_at` above, which reads every partition
too, and which this option would refuse only because it names no `dt`. It makes the date a question
somebody has to answer, which is most of what is needed.
