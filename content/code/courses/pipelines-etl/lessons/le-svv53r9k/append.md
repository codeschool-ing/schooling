---
title: Append, and why it is not enough
version: 1
---

The simplest load adds rows and touches nothing else: `INSERT INTO target SELECT ...`. It is
the right shape for data that is **only ever added to** — events, log lines, sales — and it is the
fastest load there is, because the database writes new pages and never has to find an old row.

Its weakness is everything the last eleven words leave out. To show it, Ana makes an append-only
copy of the fact table and loads 2 March into it — and then, as a scheduler retrying a run it
thought had failed would, loads it again:

```
ana@vm:~/etl$ psql -d wh -c "CREATE TABLE marts.sales_log AS SELECT * FROM marts.fact_sales WHERE false"
SELECT 0
ana@vm:~/etl$ psql -d wh -c "INSERT INTO marts.sales_log SELECT * FROM marts.fact_sales WHERE order_date = '2026-03-02'"
INSERT 0 415
ana@vm:~/etl$ psql -d wh -c "INSERT INTO marts.sales_log SELECT * FROM marts.fact_sales WHERE order_date = '2026-03-02'"
INSERT 0 415
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*), count(DISTINCT (order_id, line_no)) AS distinct_lines FROM marts.sales_log GROUP BY 1"
 order_date | count | distinct_lines 
------------+-------+----------------
 2026-03-02 |   830 |            415
(1 row)
```

**830 rows describing 415 order lines.** Every line of 2 March is now in the table twice, and every
total built on it is doubled, as lesson 1's first batch was.

An append is safe only when one of two things is true:

- **the input never repeats** — each run reads rows no previous run read, and no run is ever
  repeated. Lesson 4's watermark is how a pipeline tries to promise the first half; nothing can
  promise the second, because a failed run will be rerun;
- **the target can tell a repeat from a new row** — a key, and a load that refuses or ignores a
  row it already has.

The second is the one that holds up, and it is what the other three loads in this lesson are: each
one knows which rows it is replacing.
