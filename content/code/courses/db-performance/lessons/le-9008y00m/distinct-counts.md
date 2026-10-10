---
title: Counting the different values
version: 1
---

`n_distinct` looks like the simplest number in the summary, and it is the hardest one to get from
a sample. Counting the different values in 30,000 rows is easy. Working out from that how many
different values the other 1,970,000 rows hold is a guess, and the guess goes wrong in a
predictable direction: **too few**.

## Why a sample undercounts

Imagine a column where every value appears exactly twice in the table, five million rows and two
and a half million values. A sample of 30,000 rows catches the second copy of very few of them,
so almost every value it sees appears once. Is that a column of unique values, or one of pairs
whose partners were not sampled? The sample alone cannot tell, and `ANALYZE` uses a formula that
estimates the unseen values from how many were seen once and how many more than once. It does well
when values are either very common or truly unique, and it falls short in between.

`order_lines` is in between. Each order has one to four lines, two and a half on average:

```
market=# SELECT attname, n_distinct FROM pg_stats WHERE tablename = 'order_lines' ORDER BY attname;
   attname   | n_distinct  
-------------+-------------
 line        |           4
 order_id    | -0.28848767
 price_cents |         500
 product_id  |       43299
 quantity    |           3
(5 rows)

Time: 4.217 ms

market=# SELECT count(DISTINCT order_id) FROM order_lines;
  count  
---------
 2000000
(1 row)

Time: 563.365 ms
```

The summary says **-0.28848767**, a fraction, so 0.288 × 5,000,000 is about 1.44 million different
orders. The count says **2,000,000**. Every order has lines, so every order appears; the sample
simply saw too many of them only once to believe it. The other columns are right or close: four
line numbers, three quantities, 500 prices. `product_id` at 43,299 is the same effect in a milder
form.

## Where a distinct count is used

The selectivity of `order_id = 123` comes from `n_distinct` when the value is not on the common
list: one divided by the number of values. But the place this number does most of its work is
**grouping**. Ask the planner how many groups a `GROUP BY` will make:

```
market=# EXPLAIN SELECT order_id, count(*) FROM order_lines GROUP BY order_id;
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=0.43..191628.63 rows=1442436 width=16)
   Group Key: order_id
   ->  Index Only Scan using order_lines_pkey on order_lines  (cost=0.43..152204.31 rows=4999992 width=8)
 JIT:
   Functions: 3
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(6 rows)

Time: 0.913 ms
```

**1,442,436 groups** on the top line, the same 0.288 times the table's row count. There will be
two million. In this plan the error costs nothing, because the rows arrive already in order from
the primary key and each group is counted and passed on. But the same estimate decides, in other
plans, whether a hash table of the groups fits in `work_mem` or spills to disk, and how many rows a
join above the grouping will receive. An estimate 28% short of the truth is enough to pick the
wrong one of those. (The three `JIT` lines say how the server will compile the expressions, and do
not matter here.)

## A bigger sample: `SET STATISTICS`

The sample size is set per column, and it can be raised for the one column that needs it rather
than for the whole server:

```
market=# ALTER TABLE order_lines ALTER COLUMN order_id SET STATISTICS 1000;
ALTER TABLE
Time: 5.002 ms

market=# ANALYZE order_lines;
ANALYZE
Time: 1006.722 ms (00:01.007)

market=# SELECT n_distinct FROM pg_stats WHERE tablename = 'order_lines' AND attname = 'order_id';
 n_distinct 
------------
 -0.3375722
(1 row)

Time: 2.997 ms
```

`SET STATISTICS 1000` raises this column's target from 100 to 1000, ten times the most common
values and ten times the histogram buckets the column may keep. `ANALYZE` samples 300 times the
largest target of any column in the table, so this one now reads **300,000 rows**, and took about a
second. The estimate moved from 0.288 to **0.338**, about 1.69 million: better, and still 16% short
of two million. A sample ten times bigger still sees most orders only once.

That is the honest result of `SET STATISTICS`. It sharpens what a sample can see: the common values
of section 03, the buckets of section 04. It improves a distinct count only slowly, at the
price of a slower `ANALYZE` and a bigger summary that every plan touching the table reads. Raise it
where an estimate is wrong and a bigger sample fixes it, one column at a time, not across the
server.

## Telling the planner: `SET (n_distinct = …)`

When you know the answer, you can write it down. `order_lines` holds two and a half lines per order
by the application's own design, so the number of different orders is two fifths of the rows,
whatever the table's size: `-0.4`.

```
market=# ALTER TABLE order_lines ALTER COLUMN order_id SET (n_distinct = -0.4);
ALTER TABLE
Time: 1.576 ms

market=# ANALYZE order_lines;
ANALYZE
Time: 1005.352 ms (00:01.005)

market=# SELECT n_distinct FROM pg_stats WHERE tablename = 'order_lines' AND attname = 'order_id';
 n_distinct 
------------
       -0.4
(1 row)

Time: 2.297 ms

market=# EXPLAIN SELECT order_id, count(*) FROM order_lines GROUP BY order_id;
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=0.43..197204.43 rows=2000000 width=16)
   Group Key: order_id
   ->  Index Only Scan using order_lines_pkey on order_lines  (cost=0.43..152204.43 rows=5000000 width=8)
 JIT:
   Functions: 3
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(6 rows)

Time: 15.899 ms
```

`ANALYZE` still runs and still samples, but for this column it keeps the value it was given, and
the `GROUP BY` estimate is now **2,000,000** exactly. Because it is a fraction, it stays right as
the table grows. The setting is part of the table's definition and survives every `ANALYZE` until
somebody resets it with `ALTER TABLE … ALTER COLUMN … RESET (n_distinct)`.

The danger is the same as its strength: nothing checks it. If the application changes and orders
start having ten lines each, the summary keeps saying -0.4 and every estimate built on it is wrong
in a way no `ANALYZE` will notice. So use it for a ratio the schema guarantees, write down why next
to the `ALTER TABLE`, and prefer `SET STATISTICS` where a bigger sample is enough.

Both changes stay on `order_lines` until you undo them. The last section of this lesson puts
`market` back.
