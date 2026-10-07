---
title: Scaling up, measured
version: 1
---

To see how a query uses more cores, it needs to run long enough to time. `fact_sales` answers in
milliseconds, so this section uses a synthetic table: **twenty copies of the sales table**, one after
another, with a column saying which copy each row belongs to. Nothing in it is a real sale; it exists to
have something that takes time.

```sql
-- Twenty copies of the sales table, to have something that takes time.
CREATE TABLE fact_sales_x20 AS
SELECT f.*, c.copy FROM fact_sales f, range(20) AS c(copy);
SELECT count(*) AS rows FROM fact_sales_x20;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < x20.sql
┌──────────┐
│   rows   │
│  int64   │
├──────────┤
│ 17749540 │
└──────────┘
```

17,749,540 rows. Now one question, revenue by department and month, asked with one thread, two and four:

```sql
-- One question, asked with one, two and four threads.
.timer on
SET threads = 1;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
SET threads = 2;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
SET threads = 4;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
```

```
ana@lab:~/wh$ duckdb -list wh.duckdb < threads.sql | grep 'Run Time'
Run Time (s): real 0.001 user 0.000895 sys 0.000000
Run Time (s): real 0.358 user 0.333962 sys 0.024018
Run Time (s): real 0.000 user 0.000760 sys 0.000051
Run Time (s): real 0.164 user 0.320615 sys 0.003833
Run Time (s): real 0.000 user 0.001108 sys 0.000045
Run Time (s): real 0.126 user 0.490955 sys 0.003989
```

The lines that take no time are the `SET` statements. The three that matter:

| threads | seconds | against one thread |
|---|---|---|
| 1 | 0.358 | 1.0 times |
| 2 | 0.164 | 2.2 times as fast |
| 4 | 0.126 | 2.8 times as fast |

**Four cores did not make it four times as fast.** One run each on a shared machine moves these numbers
around, and the shape is still clear: the second thread roughly doubled the speed, and the next two added
much less. Some of the work is not split across threads at all: starting the query, building the small
lookup tables, merging each thread's partial sums into one answer. That part takes the same time
however many cores there are, and the next section turns that into arithmetic.

Notice the `user` time in the transcript: the total processor time spent, across all threads. With four
threads it is higher than the elapsed time, which is what parallel work looks like.
