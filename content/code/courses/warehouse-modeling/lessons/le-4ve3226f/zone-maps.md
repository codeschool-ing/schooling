---
title: Zone maps, skipping without an index
version: 1
---

A columnar file is divided into blocks of rows, **row groups** in Parquet. For every row group and
every column it records a few statistics: the number of rows, the number of empty values, and the
**minimum and maximum**. Here they are for `date_key`, in the file written in order of order number:

```
ana@lab:~/wh$ duckdb -c "SELECT row_group_id, row_group_num_rows AS rows, stats_min, stats_max FROM parquet_metadata('by_order.parquet') WHERE path_in_schema = 'date_key' ORDER BY row_group_id"
┌──────────────┬────────┬───────────┬───────────┐
│ row_group_id │  rows  │ stats_min │ stats_max │
│    int64     │ int64  │  varchar  │  varchar  │
├──────────────┼────────┼───────────┼───────────┤
│            0 │ 122880 │ 20240101  │ 20240514  │
│            1 │ 122880 │ 20240514  │ 20240907  │
│            2 │ 122880 │ 20240907  │ 20241212  │
│            3 │ 122880 │ 20241212  │ 20250329  │
│            4 │ 122880 │ 20250329  │ 20250705  │
│            5 │ 122880 │ 20250705  │ 20251007  │
│            6 │ 122880 │ 20251007  │ 20251218  │
│            7 │  27317 │ 20251218  │ 20251231  │
└──────────────┴────────┴───────────┴───────────┘
```

Eight row groups of 122,880 rows, and each one covers a stretch of about three months, because the rows
are in date order. A query for sales in March 2025 can read those sixteen numbers first and discard every
row group whose range does not include March: only groups 3 and 4 could hold a March sale.

These per-block minimums and maximums are called **zone maps**, and they are an index that costs almost
nothing: a few bytes per block, written as the data is written. How many row groups would March force a
reader to open, in the ordered file and in the shuffled one?

```sql
-- Every row group keeps the minimum and maximum of each column. How many
-- row groups of each file could hold a sale from March 2025?
SELECT file_name,
       count(*) AS row_groups,
       count(*) FILTER (WHERE CAST(stats_min AS INTEGER) <= 20250331
                          AND CAST(stats_max AS INTEGER) >= 20250301) AS must_be_read
FROM parquet_metadata(['shuffled.parquet', 'by_order.parquet'])
WHERE path_in_schema = 'date_key'
GROUP BY file_name ORDER BY file_name;
```

```
ana@lab:~/wh$ duckdb < zonemaps.sql
┌──────────────────┬────────────┬──────────────┐
│    file_name     │ row_groups │ must_be_read │
│     varchar      │   int64    │    int64     │
├──────────────────┼────────────┼──────────────┤
│ by_order.parquet │          8 │            2 │
│ shuffled.parquet │          8 │            8 │
└──────────────────┴────────────┴──────────────┘
```

**Two of eight in the ordered file, all eight in the shuffled one.** In the shuffled file every row group
contains dates from the whole two years, so every range includes March and nothing can be skipped. The data
is identical; only the order differs.

This is the same pruning as lesson 7's partitions, one level finer. Partitions skip files by their folder
name; zone maps skip blocks inside a file by their statistics. Both depend on the same thing: **rows that a
query wants sitting together**, which is why the sort order of a fact table is a design decision and not a
detail. DuckDB keeps zone maps for its own tables too, which is why section 12's lookup of one order is fast
without an index: the table is sorted by order number.
