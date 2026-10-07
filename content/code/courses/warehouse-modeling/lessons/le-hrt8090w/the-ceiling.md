---
title: The ceiling of one machine
version: 1
---

Cores are one limit. Memory is the other, and it bites differently: a query that runs short of
processors runs slower, while a query that runs short of memory either slows down sharply or stops.

The test: a grouping with one group for every row of the twenty copies, 17.7 million groups, which has
to hold a running total for each of them somewhere. Asked with the machine's memory, then with 200 MB,
then with 20 MB:

```sql
-- A grouping with 17.7 million groups, given less and less memory.
.timer on
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
SET memory_limit = '200MB';
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
SET memory_limit = '20MB';
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
```

```
ana@lab:~/wh$ duckdb -list wh.duckdb < memory.sql 2>&1 | grep -E 'Run Time|Error|^[0-9]'
17749540
Run Time (s): real 0.340 user 1.168995 sys 0.160492
Run Time (s): real 0.016 user 0.001318 sys 0.015076
17749540
Run Time (s): real 0.466 user 1.570202 sys 0.216842
Run Time (s): real 0.014 user 0.001582 sys 0.012248
Out of Memory Error: failed to allocate data of size 8.0 MiB (12.5 MiB/19.0 MiB used)
Run Time (s): real 0.310 user 0.952283 sys 0.115430
```

- **With the machine's memory**, 0.340 seconds.
- **With 200 MB**, 0.466 seconds. It still finished, more slowly. DuckDB is built to move parts of a
  large operation out to temporary files on disk when memory runs short, and to bring them back as it
  needs them.
- **With 20 MB**, it stopped: `Out of Memory Error`. There was not enough memory even for the pieces it
  works with.

That is the shape of the ceiling on any single machine. Below some amount of memory per query, work
moves to disk and slows down; below a smaller amount, it fails. More memory moves both lines, and a
machine can be bought with a great deal of it, but **the largest machine you can buy is a fixed number**,
and so is the disk it can write to and the network card it reads through.

The other limits of one machine are less about speed:

- **It is one point of failure.** When it is down, the warehouse is down.
- **It has one size.** A machine big enough for the busiest hour of the month is idle the rest of the
  time, and you pay for it all month.

Scaling out answers all three, and section 06 starts on what it costs.
