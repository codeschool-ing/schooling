---
title: One table, four sizes
version: 2
---

`fact_sales` exported as a CSV file, loaded into PostgreSQL, copied into a DuckDB file of its own, and
written as Parquet. The PostgreSQL copy is made by `to-postgres.sql`:

```sql
-- The same fact table, stored by row in PostgreSQL.
CREATE TABLE fact_sales (date_key int, shop_key int, book_key int, customer_key int,
    promotion_key int, order_id bigint, line_no int, quantity int, gross_cents bigint,
    discount_cents bigint, net_cents bigint);
\copy fact_sales FROM 'fact_sales.csv' WITH (FORMAT csv, HEADER true)
VACUUM ANALYZE fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb -c "COPY fact_sales TO 'fact_sales.csv' (HEADER); COPY fact_sales TO 'fact_sales.parquet'"
ana@lab:~/wh$ psql -q -f to-postgres.sql
ana@lab:~/wh$ duckdb only_sales.duckdb -c "ATTACH 'wh.duckdb' AS wh (READ_ONLY); CREATE TABLE fact_sales AS FROM wh.fact_sales"
ana@lab:~/wh$ psql -c "SELECT pg_size_pretty(pg_table_size('fact_sales')) AS postgres_table"
 postgres_table 
----------------
 79 MB
(1 row)

ana@lab:~/wh$ ls -l fact_sales.csv only_sales.duckdb fact_sales.parquet
-rw-r--r-- 1 ana ana 41418346 Oct  6 14:14 fact_sales.csv
-rw-r--r-- 1 ana ana  9492481 Oct  6 14:14 fact_sales.parquet
-rw-r--r-- 1 ana ana  9449472 Oct  6 14:14 only_sales.duckdb
```

| | bytes | against PostgreSQL |
|---|---|---|
| PostgreSQL table | 79 MB | 1 |
| CSV text | 41,418,346 | about half |
| DuckDB file | 9,449,472 | about an eighth |
| Parquet file | 9,492,481 | about an eighth |

**The same 887,477 rows, the same eleven numbers in each, take an eighth of the space by column.** Not
because the columnar files dropped anything: lesson 6 summed `net_cents` from both and got the same
total to the centavo.

PostgreSQL's row store is larger even than the text file, for reasons that are about its job rather than
waste. Every row carries a header of about two dozen bytes that the till needs for concurrent
transactions. Every number takes its full four or eight bytes whether it is 3 or 677,468. And pages keep
some free space so that an update can stay in place.

The columnar files are smaller even than the text. They are not compressing
characters, the way a zip file does. They are using what they know about each column: that it holds one
type, often a narrow range, often long runs of the same value. The next sections take those tricks one
at a time, and Parquet's own metadata shows where every byte went.
