---
title: Sort by the total, not by the mean
version: 1
---

The workload ran for a minute. Ask the tally which statements cost the server the most, sorted by
**total** time, with each one's share of the whole:

```
market=# SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms, round(100 * total_exec_time / sum(total_exec_time) OVER ()) AS pct, left(regexp_replace(query, '\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY total_exec_time DESC LIMIT 8;
 calls | total_ms | mean_ms | pct |                       query                        
-------+----------+---------+-----+----------------------------------------------------
  5497 |   166407 |   30.27 |  45 | SELECT id, title, price_cents FROM products WHERE 
   540 |   119417 |  221.14 |  32 | SELECT count(*) FROM orders WHERE status = $1
  2164 |    76810 |   35.49 |  21 | SELECT date_trunc($1, placed_at) AS day, count(*),
 27489 |     3043 |    0.11 |   1 | SELECT id, placed_at, status, total_cents FROM ord
 13787 |     1320 |    0.10 |   0 | SELECT p.title, l.quantity, l.price_cents FROM ord
  5356 |     1084 |    0.20 |   0 | INSERT INTO orders (customer_id, seller_id, placed
  5356 |      572 |    0.11 |   0 | INSERT INTO order_lines (order_id, line, product_i
  5356 |      402 |    0.08 |   0 | UPDATE orders SET total_cents = (SELECT sum(quanti
(8 rows)

Time: 3.643 ms
```

Three statements are **98% of everything the server did** in that minute — 45, 32 and 21 percent —
and every other statement the application sent, including the customer's order list that ran 27489
times, shares what is left. That is the usual shape, and it is the most useful fact in this
lesson: the work of making a database faster is almost never spread across the application. It sits
in two or three statements, and the tally names them.

The query column is cut at fifty characters to fit the screen. The three at the top are the tag
search on `products`, the operations screen's count of pending orders, and the seller dashboard's
day-by-day sum.

## The same rows, sorted by the mean

```
market=# SELECT calls, round(mean_exec_time::numeric, 2) AS mean_ms, round(total_exec_time) AS total_ms, left(regexp_replace(query, '\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY mean_exec_time DESC LIMIT 5;
 calls | mean_ms | total_ms |                       query                        
-------+---------+----------+----------------------------------------------------
   540 |  221.14 |   119417 | SELECT count(*) FROM orders WHERE status = $1
  2164 |   35.49 |    76810 | SELECT date_trunc($1, placed_at) AS day, count(*),
  5497 |   30.27 |   166407 | SELECT id, title, price_cents FROM products WHERE 
     1 |   16.87 |       17 | CREATE EXTENSION pg_stat_statements
     1 |    0.36 |        0 | SELECT calls, round(total_exec_time) AS total_ms, 
(5 rows)

Time: 3.758 ms
```

The same three, in a different order, and a different story. Sorted by the mean, the count of
pending orders is the obvious villain: **221 milliseconds a run**, six or seven times the other two. Sorted by
the total, it is second, because it runs 540 times while the tag search runs 5497.

Neither order is wrong; they answer different questions. The **mean** says how long one person
waits. The **total** says how much of the server a statement takes away from everybody else, and
that is what decides whether the next customer's request finds a free processor. A statement of 0.11
milliseconds that runs 27489 times a minute costs the server more than one of 200 that runs once an
hour, and a list sorted by the mean would never show it.

So the rule this course follows is: **find candidates by total, then read their mean** to know what
fixing one would give each user. The tag search wins on both counts, which makes it the first
target by any measure. Lesson 8 is where it gets the index it needs.

## One row, read whole

Two lines of the tally say a lot more than one column. Here is the seller dashboard's row in full,
with `\x` turning each column into a line of its own:

```
market=# \x on
Expanded display is on.

market=# SELECT queryid, calls, total_exec_time, min_exec_time, max_exec_time, mean_exec_time, stddev_exec_time, rows, shared_blks_hit, shared_blks_read, query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') AND query LIKE '%date_trunc%';
-[ RECORD 1 ]----+--------------------------------------------------------------------
queryid          | 4646798757709325093
calls            | 2164
total_exec_time  | 76810.45463800027
min_exec_time    | 12.083803000000001
max_exec_time    | 116.41520399999999
mean_exec_time   | 35.4946648049907
stddev_exec_time | 14.829679595729468
rows             | 62120
shared_blks_hit  | 7276882
shared_blks_read | 1181
query            | SELECT date_trunc($1, placed_at) AS day, count(*), sum(total_cents)+
                 | FROM orders                                                        +
                 | WHERE seller_id = $2 AND placed_at >= $3                           +
                 | GROUP BY 1 ORDER BY 1

Time: 2.286 ms
```

`calls` times `mean_exec_time` is `total_exec_time`: 2164 runs at 35.5 milliseconds each, 76.8
seconds of the server in one minute. The spread is the first thing worth reading. The fastest run
took **12 milliseconds and the slowest 116**, nearly ten times as long, and the standard deviation of
14.8 against a mean of 35.5 says that this was not one unlucky run but a statement whose cost depends
on which seller it was asked about. Some sellers have more December orders than others.

The two page counters say where the data came from: **7276882 pages found in memory** and 1181
read from outside it. Pages are 8 kB each, so that is close to 60 GB of page reads in a minute, for a
dashboard returning 62120 rows in total — twenty-nine rows a call. A statement that reads that much
to return that little is a statement doing work it does not need, and lesson 3 is about reading
exactly where.
