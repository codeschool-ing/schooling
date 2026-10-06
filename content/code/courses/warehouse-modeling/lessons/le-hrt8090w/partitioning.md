---
title: Partitioning, which is not distribution
version: 1
---

The two words are mixed up constantly, and they do different jobs.

- **Distribution** decides **which machine** a row lives on, to spread the work.
- **Partitioning** decides **which file or segment** a row lives in, so that a query can skip the ones it
  does not need.

They are independent: a table can be distributed across nodes by order number and, on each node,
partitioned by month. One machine is enough to see partitioning work. Write the sales as Parquet files, one
folder per year and month:

```sql
-- The sales, written as Parquet files, one folder per year and month.
COPY (SELECT f.*, d.year, d.month FROM fact_sales f JOIN dim_date d USING (date_key))
TO 'sales_by_month' (FORMAT parquet, PARTITION_BY (year, month));
```

```
ana@lab:~/wh$ duckdb wh.duckdb < lake.sql
ana@lab:~/wh$ ls sales_by_month sales_by_month/year=2025 | head -8
sales_by_month:
year=2024
year=2025

sales_by_month/year=2025:
month=1
month=10
month=11
ana@lab:~/wh$ find sales_by_month -name "*.parquet" | wc -l
24
```

The folder names carry the values: `year=2025/month=3` holds the sales of March 2025 and nothing else. This
layout is called **Hive-style partitioning**, after the system that made it common, and every engine in
lessons 9 and 10 reads it. Now ask for March 2025, and ask DuckDB what it read:

```sql
EXPLAIN ANALYZE
SELECT sum(net_cents)
FROM read_parquet('sales_by_month/*/*/*.parquet', hive_partitioning = true)
WHERE year = 2025 AND month = 3;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < pruning.sql | grep -E 'Filters|year = |Scanning|Total Files'
EXPLAIN ANALYZE SELECT sum(net_cents) FROM read_parquet('sales_by_month/*/*/*.parquet', hive_partitioning = true) WHERE year = 2025 AND month = 3;
│       File Filters:       │
│  (year = 2025)(month = 3) │
│    Scanning Files: 1/24   │
│    Total Files Read: 1    │
```

**`Scanning Files: 1/24`.** The filter on `year` and `month` was applied to the folder names before
anything was opened, and 23 of the 24 files were never touched. That is **partition pruning**, and it is the
cheapest speed-up in analytics: the work not done is free.

Three rules make it pay:

- **Partition by what queries filter on.** Nearly every warehouse query filters by date, which is why date
  is the usual choice.
- **Not too fine.** Partitioning sales by day would make 731 folders of small files, and opening a file
  has a fixed cost however little is in it. Lesson 10 returns to the small-file problem.
- **Not too coarse.** One partition per year would read a whole year to answer a question about March.
