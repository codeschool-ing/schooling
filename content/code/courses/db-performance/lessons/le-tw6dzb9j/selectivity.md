---
title: Selectivity, and the point where the plan flips
version: 1
---

**Selectivity** is the share of a table's rows a condition keeps: a day of orders is a small
fraction, a year is more than half. The common belief is that there is a number — "an index is
used below 5%", or 10, or 15 — and that the planner switches from index to table at that line.
There is no such number. There is a crossing point, and where it sits depends on the column as
much as on the share.

## Widening a date range

With parallel plans allowed again, as the server ships, ask for the plan of the same sum over a
day, a month and a year:

```
market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=135.56..135.57 rows=1 width=8)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..127.77 rows=3117 width=4)
         Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-06-02 00:00:00-03'::timestamp with time zone))
(3 rows)

Time: 2.262 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-07-01';
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3780.99..3781.00 rows=1 width=8)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..3555.15 rows=90336 width=4)
         Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-07-01 00:00:00-03'::timestamp with time zone))
(3 rows)

Time: 1.007 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01';
                                                                              QUERY PLAN                                                                              
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=31313.85..31313.86 rows=1 width=8)
   ->  Gather  (cost=31313.64..31313.85 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=30313.64..30313.65 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=458656 width=4)
                     Filter: ((placed_at >= '2025-01-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2026-01-01 00:00:00-03'::timestamp with time zone))
(6 rows)

Time: 0.736 ms
```

A day and a month are both index scans; the year is a parallel sequential scan. The planner did not
look up a threshold. It priced each access path for each range and kept the cheapest, and between a
month and a year the price of walking the index overtook the price of reading the table.

## Widening a range of customers

Now the same with customers, a hundred, twenty thousand and sixty thousand of them:

```
market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1000 AND 1100;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Aggregate  (cost=3453.67..3453.68 rows=1 width=8)
   ->  Bitmap Heap Scan on orders  (cost=19.56..3450.95 rows=1086 width=4)
         Recheck Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..19.29 rows=1086 width=0)
               Index Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
(5 rows)

Time: 1.914 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                  QUERY PLAN                                                   
---------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=22170.23..22170.24 rows=1 width=8)
   ->  Gather  (cost=22170.02..22170.23 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=21170.02..21170.03 rows=1 width=8)
               ->  Parallel Bitmap Heap Scan on orders  (cost=3017.14..20957.75 rows=84907 width=4)
                     Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
                     ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0)
                           Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
(8 rows)

Time: 0.627 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 60000;
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=30793.77..30793.78 rows=1 width=8)
   ->  Gather  (cost=30793.55..30793.76 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=29793.55..29793.56 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=250621 width=4)
                     Filter: ((customer_id >= 1) AND (customer_id <= 60000))
(6 rows)

Time: 0.475 ms
```

A hundred customers already get a bitmap scan, not an index scan. Twenty thousand get a parallel
bitmap scan; sixty thousand, a parallel sequential scan. Side by side, with the share of the table
each condition keeps:

| condition | rows estimated | share of `orders` | plan |
|---|---|---|---|
| one day of `placed_at` | 3117 | 0.16% | Index Scan |
| one month of `placed_at` | 90336 | 4.5% | Index Scan |
| one year of `placed_at` | about 1.1 million | 55% | Parallel Seq Scan |
| 100 values of `customer_id` | 1086 | 0.05% | Bitmap Heap Scan |
| 20000 values of `customer_id` | 203777 | 10% | Parallel Bitmap Heap Scan |
| 60000 values of `customer_id` | about 600000 | 30% | Parallel Seq Scan |

The parallel plans print their row estimates per process, which is why the table rounds those two
rather than copying a number off the screen.

**A month of orders, 4.5% of the table, is fetched one row at a time through the index, and a
hundred customers' orders, a hundredth of that share, are not.** The difference is the correlation
of the last section. On `placed_at` the rows of a month sit together on about 750 consecutive
pages, so following the index costs about what reading those pages in order would. On
`customer_id`, a thousand rows means a thousand pages scattered across the file, and the planner
gathers them into a bitmap so that it at least reads them in order.

## What moves the crossing point

The planner weighs four things, and each of them has appeared in this lesson or the last:

- **how many rows** the condition keeps, which the planner knows only as an estimate from its
  statistics;
- **how many pages** those rows are on, which is what correlation predicts;
- **the price list** — `random_page_cost` at 4 against `seq_page_cost` at 1 says a page out of
  order costs four reads in order, and that ratio decides how soon a scattered index scan loses;
- **what the query does with the rows**: an `ORDER BY` the index already satisfies, or a `LIMIT`
  that stops early, makes an index scan cheaper than its row count suggests.

The price list deserves a word, because it is the input people change. The default 4 describes a
spinning disk, where a seek is expensive. On solid-state storage a random read costs much closer
to a sequential one, and lowering `random_page_cost` towards 1 moves every crossing point towards
the index. That is a statement about the machine, made once in the server's configuration after
measuring, and `db-administration` is where it belongs. Changing it to make one query pick one plan
is the mistake the next section is about.

## The estimate is an input like any other

Every row count in the table above is an estimate, and the planner chose each plan on it. Here the
estimates are close: 3117 expected for a day that held 2801, 1086 for 991. When an estimate is
wrong by a factor of a hundred, the planner picks the plan for a selectivity that does not exist.
A good index is skipped, or a good sequential scan is replaced by ten thousand random reads. **Reading the access path is only half of reading a plan; the other half is
checking the estimate it was chosen on.** Lesson 6 is about the estimate that is wrong, and lesson
7 about the statistics it comes from.
