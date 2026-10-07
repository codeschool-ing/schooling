---
title: A table large enough to show the difference
version: 1
---

The shop's thirty thousand lines are too few for the next three decisions to show: every method
finishes in milliseconds and the differences are noise. So, for this lesson only, Ana makes a larger
table, and says how:

```
-- Made for this lesson: the real fact table, copied a hundred times, each copy
-- moved back by three weeks more than the last and given order ids of its own.
DROP SCHEMA IF EXISTS big CASCADE;
CREATE SCHEMA big;
CREATE TABLE big.fact_sales AS
SELECT order_date - 21 * k AS order_date, order_id + 1000000 * k AS order_id, line_no,
       shop_id, customer_id, book_id, quantity, line_cents
  FROM dbt_marts.fact_sales, generate_series(0, 99) AS k;
ANALYZE big.fact_sales;
```

The real fact table, a hundred times, each copy moved back three weeks further than the last. The
copies are not real sales, and nothing reads them but this lesson. What they keep from the real data
is its shape — the same days of the week, the same mix of shops and books — so that what is true of
reading and writing them is true of a real table of that size.

```
ana@vm:~/etl$ psql -q -d wh -c "\timing on" -f big.sql
psql:big.sql:3: NOTICE:  schema "big" does not exist, skipping
Time: 0.373 ms
Time: 0.791 ms
Time: 2480.087 ms (00:02.480)
Time: 253.284 ms
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS lines, min(order_date), max(order_date), pg_size_pretty(pg_total_relation_size('big.fact_sales')) AS size FROM big.fact_sales"
  lines  |    min     |    max     |  size  
---------+------------+------------+--------
 3512100 | 2020-04-23 | 2026-03-21 | 202 MB
(1 row)
```

**Three and a half million lines, six years of dates, 202 MB**, made in under three seconds. Still
small next to a real warehouse, and large enough that a query reading all of it takes a noticeable
fraction of a second while one reading the right part of it does not.
