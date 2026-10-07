---
title: Getting the data across
version: 1
---

Before anything can be modelled it has to be in the warehouse. How data is moved, on what
schedule, and what happens when a load fails halfway is the subject of `pipelines-etl`. Ana's lab
does the simplest thing that works, and it is worth seeing once because every later table is
built from it.

The extract is a shell script that asks PostgreSQL for each table as a CSV file:

```sh
#!/bin/sh
# Copy every table of the shop's database into extract/, one CSV file each.
set -e
mkdir -p extract
for t in shops categories publishers authors books book_authors customers \
         customer_changes promotions orders order_lines payments stock_counts \
         events event_attendance; do
  psql -q -c "\copy $t TO 'extract/$t.csv' WITH (FORMAT csv, HEADER true)"
done
```

```
ana@lab:~/wh$ sh extract.sh
ana@lab:~/wh$ ls -l extract | head -6
total 91088
-rw-r--r-- 1 ana ana    42211 Oct  6 13:22 authors.csv
-rw-r--r-- 1 ana ana    39358 Oct  6 13:22 book_authors.csv
-rw-r--r-- 1 ana ana   212957 Oct  6 13:22 books.csv
-rw-r--r-- 1 ana ana      707 Oct  6 13:22 categories.csv
-rw-r--r-- 1 ana ana   655344 Oct  6 13:22 customer_changes.csv
ana@lab:~/wh$ head -3 extract/orders.csv
order_id,shop_id,customer_id,ordered_at,status,shipping_cents,paid_at,shipped_at,delivered_at
100001,7,23316,2024-01-01 01:26:22-03,delivered,1490,2024-01-01 01:48:58-03,2024-01-02 15:39:14-03,2024-01-04 16:44:59-03
100002,7,37695,2024-01-01 02:15:39-03,delivered,1490,2024-01-01 02:34:38-03,2024-01-02 14:57:59-03,2024-01-08 10:58:01-03
```

The files land in `extract/`, one per table, as the operational database had them at the moment
of the copy.

## Staging, and a type the file cannot carry

A CSV file has no types: `9786514429742` is thirteen characters, and whether they are a number is
a guess. Ask DuckDB to read the books file and it guesses:

```
ana@lab:~/wh$ duckdb -c "SELECT isbn, typeof(isbn) AS type FROM read_csv('extract/books.csv') LIMIT 2"
┌───────────────┬─────────┐
│     isbn      │  type   │
│     int64     │ varchar │
├───────────────┼─────────┤
│ 9786514429742 │ BIGINT  │
│ 9786596648567 │ BIGINT  │
└───────────────┴─────────┘
```

**An ISBN is an identifier made of digits, not a number.** Nobody adds two of them. Read as an
integer, a code that starts with a zero loses it, as an old ten-digit ISBN or a CEP from São Paulo
would, and a join against a correctly typed column elsewhere silently finds nothing. So the staging script says what the column is:

```sql
-- The extract, loaded as it arrived: one table per CSV file, in a schema of
-- its own, so nothing downstream reads a file directly.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA staging;
CREATE TABLE staging.shops            AS FROM read_csv('extract/shops.csv', sample_size = -1);
CREATE TABLE staging.categories       AS FROM read_csv('extract/categories.csv', sample_size = -1);
CREATE TABLE staging.publishers       AS FROM read_csv('extract/publishers.csv', sample_size = -1);
CREATE TABLE staging.authors          AS FROM read_csv('extract/authors.csv', sample_size = -1);
CREATE TABLE staging.books            AS FROM read_csv('extract/books.csv', sample_size = -1,
                                                    types = {'isbn': 'VARCHAR'});
CREATE TABLE staging.book_authors     AS FROM read_csv('extract/book_authors.csv', sample_size = -1);
CREATE TABLE staging.customers        AS FROM read_csv('extract/customers.csv', sample_size = -1);
CREATE TABLE staging.customer_changes AS FROM read_csv('extract/customer_changes.csv', sample_size = -1);
CREATE TABLE staging.promotions       AS FROM read_csv('extract/promotions.csv', sample_size = -1);
CREATE TABLE staging.orders           AS FROM read_csv('extract/orders.csv', sample_size = -1);
CREATE TABLE staging.order_lines      AS FROM read_csv('extract/order_lines.csv', sample_size = -1);
CREATE TABLE staging.payments         AS FROM read_csv('extract/payments.csv', sample_size = -1);
CREATE TABLE staging.stock_counts     AS FROM read_csv('extract/stock_counts.csv', sample_size = -1);
CREATE TABLE staging.events           AS FROM read_csv('extract/events.csv', sample_size = -1);
CREATE TABLE staging.event_attendance AS FROM read_csv('extract/event_attendance.csv', sample_size = -1);
```

`sample_size = -1` makes DuckDB read the whole file before choosing a type, instead of the first
few thousand rows. `order_lines.promotion_id` is empty in almost every row near the start of the
file, and a guess from those rows makes it text.

```
ana@lab:~/wh$ duckdb wh.duckdb < staging.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'staging' ORDER BY rows DESC LIMIT 5"
┌──────────────┬────────┐
│  table_name  │  rows  │
│   varchar    │ int64  │
├──────────────┼────────┤
│ order_lines  │ 895332 │
│ payments     │ 586405 │
│ orders       │ 577468 │
│ stock_counts │ 197574 │
│ customers    │  40000 │
└──────────────┴────────┘
```

**`staging` is a schema of its own, and nothing outside the load reads it.** It is the extract as
it arrived, still in the operational shape: the dimensional tables in the next sections are built
from it, and the reports are built on those. Keeping that layer separate means a report never
depends on how a file happened to be laid out, and a load can be rerun from staging without asking
the shop's database again.
