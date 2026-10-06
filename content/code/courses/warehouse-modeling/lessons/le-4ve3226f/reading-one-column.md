---
title: Reading one column
version: 1
---

The simplest question a warehouse can be asked: total revenue. One column, summed. PostgreSQL, asked what
it read:

```
ana@lab:~/wh$ psql -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT sum(net_cents) FROM fact_sales" | grep -E 'Seq Scan|Buffers' | head -2
   Buffers: shared hit=2080 read=8064
   ->  Seq Scan on fact_sales (actual rows=887477 loops=1)
ana@lab:~/wh$ psql -c "SELECT pg_relation_size('fact_sales') / 8192 AS pages"
 pages 
-------
 10144
(1 row)
```

**10,144 pages, all of them.** 2,080 were already in memory and 8,064 came from disk, and between them they
are every page of the table. A row store cannot read `net_cents` alone, because `net_cents` is not stored
alone: it is the last eight bytes of every row, and the rows fill the pages.

Parquet, asked how many bytes each column takes:

```sql
-- How the Parquet file stores each column: bytes before and after encoding.
SELECT path_in_schema               AS column_name,
       sum(total_uncompressed_size) AS raw_bytes,
       sum(total_compressed_size)   AS stored_bytes
FROM parquet_metadata('fact_sales.parquet')
GROUP BY ALL
ORDER BY stored_bytes DESC;
```

```
ana@lab:~/wh$ duckdb < columns.sql
┌────────────────┬───────────┬──────────────┐
│  column_name   │ raw_bytes │ stored_bytes │
│    varchar     │  int128   │    int128    │
├────────────────┼───────────┼──────────────┤
│ order_id       │   7100064 │      2589196 │
│ customer_key   │   5364545 │      2381376 │
│ book_key       │   1502747 │      1419059 │
│ net_cents      │   1140419 │      1119464 │
│ gross_cents    │   1029019 │      1017354 │
│ shop_key       │    328753 │       311035 │
│ line_no        │    337363 │       249141 │
│ quantity       │    221360 │       116206 │
│ discount_cents │    240602 │        93321 │
│ promotion_key  │     54672 │        29578 │
│ date_key       │      5529 │         5602 │
└────────────────┴───────────┴──────────────┘
  11 rows                         3 columns
```

**To sum `net_cents`, a columnar reader reads 1,119,464 bytes**: that column's stored bytes and nothing else,
out of a file of 9,492,481. Twelve per cent of the file, against all of the PostgreSQL table.

That is the first and simplest advantage of storing by column, and it grows with the width of the table.
`fact_sales` has eleven narrow columns. A wide table like lesson 6's, with 31 columns including titles and
author names, would give a row store thirty columns of bytes to carry for every one it uses.

The two engines, timed on that sum:

```
ana@lab:~/wh$ psql -f pg-sum.sql
Timing is on.
    sum     
------------
 9574389852
(1 row)

Time: 84.845 ms
ana@lab:~/wh$ duckdb wh.duckdb < duck-sum.sql
┌────────────────┐
│ sum(net_cents) │
│     int128     │
├────────────────┤
│     9574389852 │
└────────────────┘
Run Time (s): real 0.002 user 0.005144 sys 0.000000
```

84.845 milliseconds in PostgreSQL against 0.002 seconds in DuckDB: about forty times, for one run each.
Reading less is part of it. Section 11 is the rest.
