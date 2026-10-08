---
title: What repetition costs in bytes
version: 2
---

The other argument against repeating values is space. It depends almost entirely on how the database
stores the data, so measure it twice: once in PostgreSQL, which stores rows, and once in Parquet, the
columnar file format lesson 8 takes apart.

```sql
SELECT 'star: fact and five dimensions' AS model,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS size
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'wh' AND c.relkind = 'r' AND c.relname <> 'sales_wide'
UNION ALL
SELECT 'one big table', pg_size_pretty(pg_total_relation_size('wh.sales_wide'));
```

```sql
COPY fact_sales    TO 'pq/fact_sales.parquet';
COPY dim_date      TO 'pq/dim_date.parquet';
COPY dim_shop      TO 'pq/dim_shop.parquet';
COPY dim_book      TO 'pq/dim_book.parquet';
COPY dim_customer  TO 'pq/dim_customer.parquet';
COPY dim_promotion TO 'pq/dim_promotion.parquet';
COPY sales_wide    TO 'pq/sales_wide.parquet';
SELECT CASE WHEN file LIKE '%sales_wide%' THEN 'one big table'
            ELSE 'star: fact and five dimensions' END AS model,
       sum(size) AS bytes
FROM (SELECT filename AS file, size FROM read_blob('pq/*.parquet'))
GROUP BY ALL ORDER BY bytes;
```

The copies come from two more files. `export.sql` writes the star and the wide table out of DuckDB
as CSV, and `pg-load.sql` loads them into a schema of their own in PostgreSQL:

```sql
-- The star and the wide table, as files PostgreSQL can load and as Parquet.
COPY fact_sales    TO 'pg/fact_sales.csv'    (HEADER);
COPY dim_date      TO 'pg/dim_date.csv'      (HEADER);
COPY dim_shop      TO 'pg/dim_shop.csv'      (HEADER);
COPY dim_book      TO 'pg/dim_book.csv'      (HEADER);
COPY dim_customer  TO 'pg/dim_customer.csv'  (HEADER);
COPY dim_promotion TO 'pg/dim_promotion.csv' (HEADER);
COPY sales_wide    TO 'pg/sales_wide.csv'    (HEADER);
```

```sql
-- The same tables, stored by row in PostgreSQL.
CREATE SCHEMA wh;
CREATE TABLE wh.fact_sales (date_key int, shop_key int, book_key int, customer_key int,
    promotion_key int, order_id bigint, line_no int, quantity int, gross_cents bigint,
    discount_cents bigint, net_cents bigint);
CREATE TABLE wh.dim_date (date_key int, date date, year int, quarter int, month int,
    month_name text, day_of_month int, day_of_week int, day_name text, is_weekend bool,
    is_holiday bool, holiday text);
CREATE TABLE wh.dim_shop (shop_key int, shop_id int, shop_name text, city text, state text,
    region text, channel text, opened_on date);
CREATE TABLE wh.dim_book (book_key int, book_id int, isbn text, title text, authors text,
    format text, category text, subcategory text, department text, publisher text,
    published_on date);
CREATE TABLE wh.dim_customer (customer_key int, customer_id int, name text, tier text,
    city text, state text, valid_from timestamptz, valid_to timestamptz, is_current bool);
CREATE TABLE wh.dim_promotion (promotion_key int, promotion_id int, code text,
    promotion_name text, percent_off int, starts_on date, ends_on date, applies_to text);
CREATE TABLE wh.sales_wide (order_id bigint, line_no int, quantity int, gross_cents bigint,
    discount_cents bigint, net_cents bigint, date date, year int, month int, month_name text,
    day_name text, is_weekend bool, is_holiday bool, shop_name text, shop_city text,
    shop_state text, region text, channel text, isbn text, title text, authors text,
    format text, category text, subcategory text, department text, publisher text, tier text,
    customer_city text, customer_state text, promotion_code text, promotion_name text);
\copy wh.fact_sales FROM 'pg/fact_sales.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_date FROM 'pg/dim_date.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_shop FROM 'pg/dim_shop.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_book FROM 'pg/dim_book.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_customer FROM 'pg/dim_customer.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_promotion FROM 'pg/dim_promotion.csv' WITH (FORMAT csv, HEADER true)
\copy wh.sales_wide FROM 'pg/sales_wide.csv' WITH (FORMAT csv, HEADER true)
VACUUM ANALYZE;
```

```
ana@lab:~/wh$ mkdir -p pg pq && duckdb wh.duckdb < export.sql
ana@lab:~/wh$ psql -q -f pg-load.sql
ana@lab:~/wh$ psql -f pg-sizes.sql
             model              |  size  
--------------------------------+--------
 star: fact and five dimensions | 85 MB
 one big table                  | 242 MB
(2 rows)

ana@lab:~/wh$ duckdb wh.duckdb < pq-sizes.sql
┌────────────────────────────────┬──────────┐
│             model              │  bytes   │
│            varchar             │  int128  │
├────────────────────────────────┼──────────┤
│ star: fact and five dimensions │ 10911040 │
│ one big table                  │ 14446367 │
└────────────────────────────────┴──────────┘
```

| | star | one big table | wide against star |
|---|---|---|---|
| PostgreSQL, by row | 85 MB | 242 MB | 2.8 times |
| Parquet, by column | 10,911,040 bytes | 14,446,367 bytes | 1.3 times |

**By row, the wide table costs nearly three times the star.** Every row carries the title, the authors,
the publisher, the shop's name and city, all written out in full, 887,477 times.

**By column, it costs about a third more.** A column of department names is the same four words repeated
in long runs. A columnar format stores a run of repeated words as the word and a count, or as a
small number pointing into a list of the words. Lesson 8 shows exactly how. The repetition that tripled
the size of a row store barely moves a column store.

That is the main reason denormalised models became normal in analytics. **The space argument for
normalisation was made in a world of row stores**, and in a column store most of it is gone. The update
argument from the previous section is not, and the next section looks at what the space bought.
