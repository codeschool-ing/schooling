---
title: Rebuilding everything, or the part that changed
version: 1
---

Lesson 11 made `fact_sales` incremental and lesson 15 gave it a thirty-day window, both on the
argument that rebuilding the whole table every night is wasteful. On the large table the argument
can be measured. Each approach runs in a transaction that is then rolled back, so both start from
the same table:

```
-- Two ways to bring the table up to date, each inside a transaction that is
-- rolled back, so that both start from the same table.
\timing on
BEGIN;
-- 1. rebuild it whole
CREATE TABLE big.fact_sales_new AS SELECT * FROM big.fact_sales;
ROLLBACK;
BEGIN;
-- 2. replace the last thirty days
DELETE FROM big.fact_sales WHERE order_date >= DATE '2026-03-21' - 30;
INSERT INTO big.fact_sales SELECT * FROM dbt_marts.fact_sales WHERE order_date >= DATE '2026-03-21' - 30;
ROLLBACK;
```

```
ana@vm:~/etl$ psql -q -d wh -f rebuild.sql
Time: 0.150 ms
Time: 2240.156 ms (00:02.240)
Time: 26.844 ms
Time: 0.089 ms
Time: 7.712 ms
Time: 21.896 ms
Time: 0.225 ms
```

The times are in the order the statements ran. Copying the whole table: **about two and a quarter
seconds**. Deleting the last thirty days, found through the index, and inserting them again: **about
thirty milliseconds** between the two statements. Two orders of magnitude, and the gap widens with
every year of history, because the whole rebuild grows with the table and the window does not.

That is the case for incremental loads, and it comes with the price lessons 11 and 15 paid for it:
a window only puts right what falls inside it, so it needs the drift test to say when it was not
enough, and an occasional full rebuild to put right what it missed. On a table this size a full
rebuild once a week is affordable; on one a thousand times larger, it is a decision about money as
much as about time.
