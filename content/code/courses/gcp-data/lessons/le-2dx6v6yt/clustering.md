---
title: Clustering, and the blocks a filter skips
version: 1
---

**Clustering sorts the rows of each partition by up to four columns, so that a filter on them can
skip blocks of storage.** It is the second of the two decisions, and the one that works where a
partition cannot: on a column with too many values to partition by, or as a second filter inside the
partition the first one chose. Quitanda's dashboards ask about one store on one day. The day is the
partition; the store is the cluster.

**What makes a skip possible is the same thing lesson 13 measured in a Parquet file**: for each block
of storage, the smallest and largest value of a column in it. If the rows are sorted by `store_id`,
each block holds a narrow range of stores, and a filter `store_id = 7` reads only the blocks whose
range contains 7. If they are not sorted, every block holds every store, and the filter reads them
all.

## The row groups, in the two layouts

**A Parquet file keeps that range for every row group**, and DuckDB's `parquet_metadata` function
reads it out of the file's footer without reading a row. `orders_by_store` is sorted by store within
each day, in groups of 2,048 rows. For the last day of the data:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT row_group_id, stats_min_value AS min_store, stats_max_value AS max_store FROM parquet_metadata('warehouse/orders_by_store/dt=2026-09-29/*.parquet') WHERE path_in_schema = 'store_id' ORDER BY row_group_id"
┌──────────────┬───────────┬───────────┐
│ row_group_id │ min_store │ max_store │
│    int64     │  varchar  │  varchar  │
├──────────────┼───────────┼───────────┤
│            0 │ 1         │ 3         │
│            1 │ 3         │ 5         │
│            2 │ 5         │ 7         │
│            3 │ 7         │ 9         │
│            4 │ 9         │ 11        │
│            5 │ 11        │ 13        │
│            6 │ 13        │ 15        │
│            7 │ 15        │ 16        │
│            8 │ 1         │ 1         │
└──────────────┴───────────┴───────────┘
```

**Each group holds two or three stores**, 1 to 3, 3 to 5 and so on up to 16. The ninth group, 1 to 1,
is a few orders of store 1 written by a second thread of DuckDB after the others, which is how a
parallel writer behaves and does no harm to the skipping. The same question, asked of both layouts of
that day:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT CASE WHEN file_name LIKE '%by_store%' THEN 'by store' ELSE 'by time' END AS layout, count(*) AS row_groups, count(*) FILTER (WHERE stats_min_value::INT <= 7 AND stats_max_value::INT >= 7) AS may_hold_store_7 FROM parquet_metadata(['warehouse/orders_by_time/dt=2026-09-29/data_0.parquet', 'warehouse/orders_by_store/dt=2026-09-29/data_0.parquet']) WHERE path_in_schema = 'store_id' GROUP BY layout ORDER BY layout"
┌──────────┬────────────┬──────────────────┐
│  layout  │ row_groups │ may_hold_store_7 │
│ varchar  │   int64    │      int64       │
├──────────┼────────────┼──────────────────┤
│ by store │          9 │                2 │
│ by time  │          9 │                9 │
└──────────┴────────────┴──────────────────┘
```

**Sorted by store, two of the nine groups might hold store 7; in arrival order, all nine might.** A
filter on `store_id = 7` reads two ninths of the day's rows in one layout and the whole day in the
other, for the same rows and the same file sizes. That is clustering, measured on Parquet's row
groups. BigQuery's blocks are its own and are not Parquet row groups, so two ninths is an
illustration of the effect and not BigQuery's number for this table.

## Clustering in BigQuery

**A table names up to four clustering columns, and their order matters.** `CLUSTER BY store_id`
in the DDL of the first section is one; `CLUSTER BY store_id, payment` would sort by store first and
by payment within each store. As with a compound sort key, a filter on the first column skips the
most, a filter on the second skips only within each value of the first, and a filter on the second
alone skips little. The columns have to be top-level columns of the types Google's documentation
lists, which include `STRING`, `INT64`, `DATE`, `TIMESTAMP` and `BOOL`.

**BigQuery keeps the table sorted on its own, at no charge.** As new rows arrive, a nightly load
appends blocks that are sorted among themselves but not with the old ones, and the documentation
describes automatic reclustering, done in the background without using the project's slots or bytes.
Nobody schedules it and nobody pays for it, which is a difference from warehouses where re-sorting a
table is a job somebody remembers to run.

**Clustering does not show on the dry run.** The pricing page says that a query "that includes a
filter on the clustered columns" prunes blocks "and can reduce the number of scanned bytes", and
Google's documentation of clustered tables adds the catch: the bytes the dry run estimates are an
upper bound, worked out before any block is skipped, and the bill afterwards is often lower. A
partition filter is known before the query runs; a cluster skip is only known while it runs. So
**partitioning is the saving you can promise and clustering is the saving you find on the bill.**

## Which columns to cluster by

**The columns that queries filter on, in the order of how often they do**, after the partitioning
column has taken the first. At Quitanda that is `store_id`, then perhaps `payment`. A column with
very few values, such as `payment` with three, sorts into long runs and skips well; one with a value
per row, such as `order_id`, sorts into short runs that a filter on one order can skip almost
completely and that a filter on anything else gains nothing from. Clustering on a column nobody filters
on costs nothing on the bill, and buys nothing either.
