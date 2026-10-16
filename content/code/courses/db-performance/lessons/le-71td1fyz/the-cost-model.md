---
title: The cost model, worked by hand
version: 1
---

The cost on a plan looks like a measurement and is treated like one, and it is neither a time nor
anything mysterious. **It is arithmetic: a handful of settings multiplied by numbers the server
keeps about each table.** Working one out by hand, once, is what turns the planner from an oracle
into a calculator whose inputs you can check — and a plan that looks wrong is almost always a
calculator fed a wrong input.

## The inputs

Two kinds. The first is what PostgreSQL knows about each table's size, kept in the catalogue
table `pg_class`: `relpages`, the number of 8 kB pages, and `reltuples`, the number of rows. The
second is the price list, a few settings that say what one unit of each kind of work costs:

```
market=# SELECT relname, relpages, reltuples FROM pg_class WHERE relname IN ('orders', 'order_lines', 'products', 'customers', 'sellers', 'events') ORDER BY relname;
   relname   | relpages |  reltuples   
-------------+----------+--------------
 customers   |     2283 |       200000
 events      |    65432 | 4.999827e+06
 order_lines |    31848 | 4.999992e+06
 orders      |    16667 |        2e+06
 products    |      649 |        50000
 sellers     |        6 |         1000
(6 rows)

Time: 2.781 ms

market=# SELECT name, setting FROM pg_settings WHERE name IN ('seq_page_cost', 'random_page_cost', 'cpu_tuple_cost', 'cpu_index_tuple_cost', 'cpu_operator_cost');
         name         | setting 
----------------------+---------
 cpu_index_tuple_cost | 0.005
 cpu_operator_cost    | 0.0025
 cpu_tuple_cost       | 0.01
 random_page_cost     | 4
 seq_page_cost        | 1
(5 rows)

Time: 2.647 ms
```

The prices are relative to one number. **`seq_page_cost` is 1 by definition**: reading one page
of a table as part of a sequential pass. Everything else is priced against that:

| setting | what it prices | value |
|---|---|---|
| `seq_page_cost` | one page read in sequence | 1 |
| `random_page_cost` | one page fetched out of order, as an index scan does | 4 |
| `cpu_tuple_cost` | handling one row | 0.01 |
| `cpu_index_tuple_cost` | handling one index entry | 0.005 |
| `cpu_operator_cost` | one operator or function applied, such as one `=` or `>` | 0.0025 |

So the planner believes a page out of order costs four times a page in order, and that reading a
page costs a hundred times what handling a row does. Those are beliefs about a disk, chosen long
ago as defaults, and lesson 4 is where the four against the one decides between two plans.

## A sequential scan, by hand

A sequential scan reads every page once, in order, and handles every row once:

```
cost = relpages × seq_page_cost + reltuples × cpu_tuple_cost
     = 16667 × 1             + 2000000 × 0.01
     = 16667                 + 20000
     = 36667
```

Now ask the planner. Then add a condition, which costs one operator per row, and finally prove
the formula by changing one price and watching the total move:

```
market=# EXPLAIN SELECT * FROM orders;
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..36667.00 rows=2000000 width=37)
(1 row)

Time: 1.437 ms

market=# EXPLAIN SELECT * FROM orders WHERE total_cents > 0;
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..41667.00 rows=1999800 width=37)
   Filter: (total_cents > 0)
(2 rows)

Time: 1.030 ms

market=# SET cpu_tuple_cost = 0.02;
SET
Time: 0.851 ms

market=# EXPLAIN SELECT * FROM orders;
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..56667.00 rows=2000000 width=37)
(1 row)

Time: 0.830 ms

market=# RESET cpu_tuple_cost;
RESET
Time: 0.276 ms
```

`36667.00`, exactly. The condition `total_cents > 0` is applied to two million rows at `0.0025`
each, which adds 5000 and makes `41667.00`. And with `cpu_tuple_cost` doubled to 0.02, the
two million rows cost 40000 instead of 20000 and the total is `56667.00`: **16667 pages plus
40000 for the rows, which is the formula and nothing else.** The `RESET` puts the price back.

The startup cost of all three is `0.00`, because a sequential scan has nothing to do before its
first row: it opens the table and starts reading.

## The same sum for every table

The `pg_class` result above is enough to price a full scan of any of the six tables. Two worked
for you, to check against the planner's own numbers:

| table | pages | rows | pages × 1 | rows × 0.01 | total |
|---|---|---|---|---|---|
| `orders` | 16667 | 2000000 | 16667 | 20000 | 36667 |
| `products` | 649 | 50000 | 649 | 500 | 1149 |

`EXPLAIN SELECT * FROM products` prints `cost=0.00..1149.00`. Price the others yourself; the
drill at the end of the lesson asks for one.

## Nodes above the scan

Every node has a formula of its own, and the nodes above a scan add their share to the total
underneath. The pending count, as one plain tree:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.474 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                     QUERY PLAN                                                     
--------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=41683.50..41683.51 rows=1 width=8) (actual time=176.162..176.164 rows=1 loops=1)
   ->  Seq Scan on orders  (cost=0.00..41667.00 rows=6600 width=0) (actual time=175.277..175.912 rows=7319 loops=1)
         Filter: (status = 'pending'::text)
         Rows Removed by Filter: 1992681
 Planning Time: 0.540 ms
 Execution Time: 176.299 ms
(6 rows)

Time: 178.010 ms
```

The scan is the `41667.00` from before: pages, rows, and one `=` per row. The `Aggregate` above it
counts the rows it receives, which the planner prices as one operator per row: 6600 rows expected,
at 0.0025, is 16.5, so the aggregate cannot return anything before `41683.50`. Then it hands up
one row, at `cpu_tuple_cost`, which is the last `.01`.

The 6600 there is the planner's estimate of how many orders are pending; the real number, under
`actual`, is 7319. That estimate came from statistics about the `status` column, not from the
formula, and it matters more than any price on the list: **every node above a scan is priced on
the scan's row estimate**, so an estimate that is wrong makes every cost above it wrong with it.
Lesson 6 is about that failure, and lesson 7 about the statistics behind the estimate.

## Cost is not time

The same plan has a cost of 41683.51 and took 176 milliseconds here. There is no fixed exchange
rate between the two, and none is intended. On a cold machine the same cost takes longer; on a
faster disk, less. **The cost exists to compare plans for one query against each other**, on the
same prices, in the same second. Comparing the cost of two different queries says very little,
and comparing a cost with a timing says nothing.

One detail keeps the arithmetic honest when a table grows. `relpages` and `reltuples` are updated
by `VACUUM` and `ANALYZE`, not on every insert, so the planner does not trust them blindly: it
looks up the table's current size in pages when it plans, and scales the row count to match. On a
table that has not changed since it was last analysed, as all six here are, the two agree and
the hand calculation is exact. Lesson 6 uses a table where they do not.
