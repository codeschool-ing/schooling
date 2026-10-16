---
title: A first look, before any question
version: 1
---

The wrong way to start is with the question. Somebody asks for the average order last quarter,
you write `SELECT avg(...)`, you get a number, and the number goes into a slide. Nothing in that
sequence asked whether the table holds what its name says, whether a day is missing, or whether
one order in a thousand is a typo worth ten thousand reais.

**Exploratory analysis is the hour you spend with a table before you trust it.** It answers three
questions in order: what is in here, what does a normal row look like, and which rows are not
normal. This lesson asks them of Lantern's tables, and every fault it finds was planted by the
script — but each is a fault real data has, and the queries that find them are the ones you will
use at work.

## What is in here

```
lantern=# \dt
           List of relations
 Schema |     Name     | Type  | Owner 
--------+--------------+-------+-------
 shop   | customers    | table | ana
 shop   | order_lines  | table | ana
 shop   | orders       | table | ana
 shop   | products     | table | ana
 shop   | web_events   | table | ana
 shop   | web_sessions | table | ana
(6 rows)
```

Six tables. `products` and `customers` describe things; `orders` and `order_lines` record sales;
`web_sessions` and `web_events` record visits to the website, which lessons 9 and 10 use. The
first questions to ask any table are how many rows it has and what range it covers:

```
lantern=# SELECT count(*) AS customers, min(signed_up), max(signed_up) FROM customers;
 customers |    min     |    max     
-----------+------------+------------
      2650 | 2025-01-02 | 2026-06-17
(1 row)

lantern=# SELECT count(*) AS orders, min(ordered_at), max(ordered_at) FROM orders;
 orders |          min           |          max           
--------+------------------------+------------------------
   7102 | 2025-01-02 19:49:00-03 | 2026-06-17 23:55:00-03
(1 row)

lantern=# SELECT status, count(*) FROM orders GROUP BY status;
  status  | count 
----------+-------
 refunded |   257
 paid     |  6845
(2 rows)
```

Three facts to keep. Customers signed up from 2 January 2025 to 17 June 2026. The last order was
placed at 23:55 on 17 June — the `-03` is São Paulo's offset from UTC, which the setting in the
last section made the database print. And 257 of 7,102 orders were refunded: **a total of
"orders" that includes them is a different number from one that does not**, which is lesson 2's
whole subject.

## The grain of each table

The **grain** of a table is what one row stands for. In `orders` a row is an order; in
`order_lines` it is one product inside an order, so an order of three products has three lines.
Getting the grain wrong is the commonest way to double a total, and it is cheap to check:

```
lantern=# SELECT count(*) AS lines, count(DISTINCT order_id) AS orders FROM order_lines;
 lines | orders 
-------+--------
 11362 |   7102
(1 row)

lantern=# SELECT count(*) AS orders_without_lines
lantern-# FROM orders o
lantern-# WHERE NOT EXISTS (SELECT 1 FROM order_lines l WHERE l.order_id = o.order_id);
 orders_without_lines 
----------------------
                    0
(1 row)
```

11,362 lines across 7,102 distinct orders, and no order without a line. Both facts matter: the
first says that counting rows of `order_lines` counts products, not orders; the second says that a
join from orders to lines loses nothing. **Write the grain down the first time you check it.** It
is the sentence lesson 3 builds a whole model on.
