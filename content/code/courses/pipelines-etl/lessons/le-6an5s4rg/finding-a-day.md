---
title: Finding one day in six years
version: 1
---

Lesson 7's day replace, lesson 11's `delete+insert` and lesson 15's window all start the same way:
find the rows of a day, and delete them. How long that takes depends on how PostgreSQL finds them.
`EXPLAIN ANALYZE` runs the statement and reports how it found them. Here it runs inside a
transaction that is rolled back, so that nothing is really deleted:

```
-- How PostgreSQL finds one day's lines, and how long it takes, without keeping the change.
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
DELETE FROM big.fact_sales WHERE order_date = DATE '2026-03-16';
ROLLBACK;
```

```
ana@vm:~/etl$ psql -q -d wh -f one_day.sql
                       QUERY PLAN                       
--------------------------------------------------------
 Delete on fact_sales (actual rows=0 loops=1)
   ->  Seq Scan on fact_sales (actual rows=446 loops=1)
         Filter: (order_date = '2026-03-16'::date)
         Rows Removed by Filter: 3511654
 Planning Time: 0.251 ms
 Execution Time: 209.122 ms
(6 rows)
```

**`Seq Scan`**: to find 446 lines, PostgreSQL read every one of the three and a half million and
threw away all but those — *Rows Removed by Filter*. Two hundred milliseconds, and it grows with the
table, not with the day: a table twice the size takes twice as long to find the same 446 lines.

An **index** on `order_date` is a sorted list of dates, each pointing at its rows. Building it costs
a pass over the table, once:

```
ana@vm:~/etl$ psql -q -d wh -c "\timing on" -c "CREATE INDEX ON big.fact_sales (order_date)"
Time: 1110.572 ms (00:01.111)
ana@vm:~/etl$ psql -q -d wh -f one_day.sql
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Delete on fact_sales (actual rows=0 loops=1)
   ->  Index Scan using fact_sales_order_date_idx on fact_sales (actual rows=446 loops=1)
         Index Cond: (order_date = '2026-03-16'::date)
 Planning Time: 0.398 ms
 Execution Time: 0.321 ms
(5 rows)
```

**`Index Scan`**: straight to the 446 lines, a third of a millisecond. The day was found in a time
that does not depend on how many other days there are, which is what makes replacing one day of a
large table cheap.

An index is not free. It takes space — a copy of the column, sorted — and **every insert into the
table also inserts into the index**, so a table loaded in bulk every night pays for its indexes during
the load. The usual arrangement for a large fact table is an index on the column every load and every
report filters by, which here is the date, and as few others as the reports genuinely need.
