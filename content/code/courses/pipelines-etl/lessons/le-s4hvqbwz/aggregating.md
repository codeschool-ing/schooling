---
title: Aggregating to a grain, and building it all
version: 1
---

A mart answers a question at a **grain**: the level of detail one row describes. Ana's first mart
is one row per day, shop and category, with books and revenue:

```
-- Books and revenue by day, shop and category: one row per combination that
-- sold anything. Built from the line grain and nothing coarser, so that no
-- join can repeat a line.
DROP TABLE IF EXISTS marts.daily_sales;
CREATE TABLE marts.daily_sales AS
SELECT o.order_date,
       o.shop_id,
       b.category,
       sum(l.quantity)::integer    AS books,
       sum(l.line_cents)::bigint   AS revenue_cents
  FROM staging.order_lines l
  JOIN staging.orders o USING (order_id)
  JOIN staging.books  b USING (book_id)
 WHERE o.is_sale
 GROUP BY 1, 2, 3;
```

Two things in it are deliberate. It reads only `staging`, never `raw`. And it sums columns that live
at the grain of the table it starts from — `quantity` and `line_cents` are on the line, and the joins
go from the line *up* to its order and its book, each of which matches exactly one row. **A join
that goes up a hierarchy cannot fan out**; one that goes down it, from an order to its lines, can.

## Building every table, in order

Three files in the folder have not appeared yet, because there is nothing to say about them:
`sql/staging/00_schema.sql`, `sql/marts/00_schema.sql` and `sql/staging/books.sql`, in that order.

```sql
CREATE SCHEMA IF NOT EXISTS staging;
```

```sql
CREATE SCHEMA IF NOT EXISTS marts;
```

```sql
-- One row per book.
DROP TABLE IF EXISTS staging.books CASCADE;
CREATE TABLE staging.books AS
SELECT book_id, isbn, title, category, publisher, list_price_cents
  FROM raw.books;
```

Each SQL file builds one table, and the files have to run in an order: staging before marts, and
within each layer, the schema before its tables. Ana's runner does the simplest thing that works:

```
#!/bin/sh
# Build staging, then marts, one file at a time, in the order of their names.
# Stops at the first file that fails, and says which.
set -e
export PGOPTIONS="-c client_min_messages=warning"   # no NOTICE for each DROP IF EXISTS

for f in sql/staging/*.sql sql/marts/*.sql; do
  psql -q -v ON_ERROR_STOP=1 -d wh -f "$f"
  echo "built $f"
done
```

```
ana@vm:~/etl$ sh run_sql.sh
built sql/staging/00_schema.sql
built sql/staging/books.sql
built sql/staging/events.sql
built sql/staging/order_lines.sql
built sql/staging/orders.sql
built sql/staging/prices.sql
built sql/marts/00_schema.sql
built sql/marts/daily_sales.sql
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM marts.daily_sales WHERE order_date >= '2026-03-01' GROUP BY 1 ORDER BY 1"
 order_date | books | revenue_cents 
------------+-------+---------------
 2026-03-01 |   299 |       1979210
 2026-03-02 |   442 |       3033980
 2026-03-03 |   507 |       3355580
 2026-03-04 |   478 |       3081620
 2026-03-05 |   501 |       3363790
 2026-03-06 |   469 |       3148810
 2026-03-07 |   582 |       3978230
(7 rows)
```

**The order comes from the file names**, which is why the schema files are called `00_schema.sql`:
the zeros sort them first. It works, and it is fragile in exactly the way the course rules out for
its own content. The order of execution is inferred from the filesystem, so renaming a file can
break the build, and nothing records that `daily_sales` needs `orders` to exist first. Lesson 11
replaces this script with dbt, which works the order out from the SQL itself.

The mart for the first week, the totals per day, is the second command above.

Sunday the 1st is the quietest day of the week, as every Sunday in the data is, and Saturday the
7th is the busiest.
