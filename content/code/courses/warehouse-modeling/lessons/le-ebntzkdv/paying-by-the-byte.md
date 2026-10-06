---
title: Paying by the byte
version: 1
---

BigQuery's on-demand price page, read on 6 October 2026, says three things that matter to a modeller:

- queries cost **US$ 6.25 per tebibyte** of data processed, after the first tebibyte each month, which is
  free;
- the data processed is **the total data in the columns the query selects**, counted from the data type of
  each column: 8 bytes for an `INT64` or a `DATE`, 2 bytes plus the length of the text for a `STRING`;
- every table a query references is billed **at least 10 MB**, and so is every query.

That is a bill computed from the model, and Ana can compute it before BigQuery is involved. The query is
revenue of 2025 by department, which reads three columns of the fact table and two of each dimension:

```sql
-- The bytes BigQuery's on-demand model would bill for one query:
-- revenue of 2025 by department. Every column the query names, over every
-- row of its table, at BigQuery's logical size for the column's type.
WITH read AS (
    SELECT 'fact_sales' AS tbl, 3 * 8 * count(*) AS bytes   -- date_key, book_key, net_cents
    FROM fact_sales
    UNION ALL
    SELECT 'dim_date', 2 * 8 * count(*)                       -- date_key, year
    FROM dim_date
    UNION ALL
    SELECT 'dim_book', 8 * count(*) + sum(2 + strlen(department))
    FROM dim_book                                             -- book_key, department
)
SELECT tbl, bytes,
       greatest(bytes, 10 * 1024 * 1024) AS billed_bytes      -- 10 MB minimum per table
FROM read;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < logical-bytes.sql
┌────────────┬──────────┬──────────────┐
│    tbl     │  bytes   │ billed_bytes │
│  varchar   │  int128  │    int128    │
├────────────┼──────────┼──────────────┤
│ fact_sales │ 21299448 │     21299448 │
│ dim_date   │    11712 │     10485760 │
│ dim_book   │    55854 │     10485760 │
└────────────┴──────────┴──────────────┘
```

**21,299,448 bytes from the fact table**, every row of three columns, whatever the `WHERE` says about 2025:
in this table there is no partition or clustering column for a filter to use, so nothing reduces the
bytes billed. The two dimensions
are tiny, and each is billed the 10 MB minimum anyway.

The same arithmetic for four queries:

```sql
-- The same arithmetic for four queries, priced at US$ 6.25 per TiB.
WITH q (query, bytes) AS (VALUES
    ('revenue by department, all of fact_sales, 3 columns', 3 * 8 * 887477),
    ('SELECT * from fact_sales, all 11 columns',          11 * 8 * 887477),
    ('the first query, on 1,000 times the rows', 1000 * 3 * 8 * CAST(887477 AS BIGINT)),
    ('the same, partitioned by month, asking for one month', 1000 * 3 * 8 * CAST(887477 AS BIGINT) / 24)
)
SELECT query,
       round(bytes / 1024 / 1024 / 1024, 3)                AS gib,
       round(greatest(bytes, 10485760) / 1024 ^ 4 * 6.25, 4) AS usd
FROM q;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < scenarios.sql
┌──────────────────────────────────────────────────────┬────────┬────────┐
│                        query                         │  gib   │  usd   │
│                       varchar                        │ double │ double │
├──────────────────────────────────────────────────────┼────────┼────────┤
│ revenue by department, all of fact_sales, 3 columns  │   0.02 │ 0.0001 │
│ SELECT * from fact_sales, all 11 columns             │  0.073 │ 0.0004 │
│ the first query, on 1,000 times the rows             │ 19.837 │ 0.1211 │
│ the same, partitioned by month, asking for one month │  0.827 │  0.005 │
└──────────────────────────────────────────────────────┴────────┴────────┘
```

At Ana's size every query costs a fraction of a cent, and the free tebibyte a month would cover thousands of
them. The arithmetic matters at the third line: **a thousand times the data, about 20 GiB a query, twelve US
cents each**, run by every dashboard every time it refreshes. And at the fourth: the same query partitioned
by month and asking for one month costs a twenty-fourth.

Three design rules come straight out of the price:

- **`SELECT *` is the expensive habit.** Every column named is billed whole. Lesson 6's wide table is a
  convenience that is paid for in every query that reads it carelessly.
- **Partition and cluster by what queries filter on**, because those are the columns whose filters reduce
  the bytes billed.
- **A `LIMIT` does not make a query cheaper.** The price page counts the columns read, and a scan that stops
  showing rows at ten has still read the columns.
