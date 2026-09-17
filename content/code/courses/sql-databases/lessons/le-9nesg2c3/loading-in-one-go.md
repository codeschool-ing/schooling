---
title: Loading a relationship in one go
version: 1
---

The fix for N+1 is to tell the ORM, before the loop, that the orders will be wanted. Every mapper
has a way to say it, and underneath there are exactly two SQL shapes.

## One query per level, with the set

Fetch the fifty customers. Take their ids. Fetch every order whose `customer_id` is in that set,
in one statement, and hand each order to its customer in memory:

```
shop=# SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3]) ORDER BY customer_id, placed_at;
   id   | customer_id |          placed_at          | total  
--------+-------------+-----------------------------+--------
 258406 |           1 | 2023-12-29 04:15:09.9072+00 | 707.73
   3664 |           1 | 2025-06-11 16:30:37.6704+00 | 537.02
 933519 |           1 | 2025-07-23 19:30:48.384+00  | 996.95
 856379 |           2 | 2023-01-16 09:35:05.568+00  |  75.34
 548786 |           2 | 2023-03-04 12:53:26.9088+00 | 761.50
 418066 |           2 | 2023-03-11 05:06:16.416+00  | 898.33
 132296 |           2 | 2023-06-05 23:12:51.5232+00 | 480.19
 469617 |           2 | 2023-07-01 21:12:32.1984+00 | 187.07
 548309 |           2 | 2023-08-04 11:18:44.208+00  | 248.10
 339910 |           2 | 2023-09-25 09:19:04.2816+00 | 410.59
 179551 |           2 | 2023-10-09 01:41:05.0208+00 |  84.13
  82698 |           2 | 2024-02-16 13:46:51.1392+00 | 767.87
 813068 |           2 | 2024-05-04 09:01:28.4736+00 |  30.91
 468689 |           2 | 2024-11-15 21:47:22.56+00   | 449.14
  78609 |           2 | 2025-01-09 14:25:20.1792+00 | 824.88
 875237 |           2 | 2025-02-27 00:28:56.208+00  | 280.21
 315081 |           2 | 2025-02-28 03:37:02.7264+00 | 588.75
 199093 |           2 | 2025-08-23 21:31:48.4032+00 | 629.38
 812773 |           2 | 2025-09-27 16:48:58.752+00  | 508.08
 672465 |           3 | 2023-03-19 11:35:05.28+00   | 614.69
 410227 |           3 | 2023-03-20 00:35:30.1056+00 | 918.16
 505327 |           3 | 2023-06-08 14:29:04.9056+00 | 377.35
 937359 |           3 | 2023-06-22 19:57:59.184+00  |  39.77
 983688 |           3 | 2023-07-25 08:36:50.688+00  |  29.13
 690660 |           3 | 2023-10-28 14:22:25.0464+00 | 718.48
 699978 |           3 | 2024-06-10 06:32:00.672+00  | 468.04
 394239 |           3 | 2024-08-15 02:02:41.3664+00 | 938.50
 160670 |           3 | 2024-08-19 09:50:06.288+00  | 538.64
 772914 |           3 | 2024-12-17 10:44:42.3168+00 | 928.93
 708466 |           3 | 2024-12-24 02:45:46.1952+00 | 631.79
 370786 |           3 | 2025-02-06 17:23:09.5424+00 | 676.42
 517439 |           3 | 2025-09-10 18:10:11.5392+00 |  98.63
(32 rows)
```

Two statements for the page instead of fifty-one, whatever N is. The plan is the one lesson 10
would predict:

```
shop=# EXPLAIN ANALYZE SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=45.13..446.72 rows=110 width=22) (actual time=0.047..0.461 rows=88 loops=1)
   Recheck Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
   Heap Blocks: exact=88
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..45.08 rows=110 width=0) (actual time=0.024..0.025 rows=88 loops=1)
         Index Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
 Planning Time: 0.698 ms
 Execution Time: 0.514 ms
(7 rows)
```

A bitmap scan through the index on `customer_id`, once, for all ten ids — 88 rows in half a
millisecond. Fifty ids is the same shape with a longer array, and a hundred thousand ids is the
point at which the ORM sends the array in chunks.

This is what Django calls `prefetch_related`, Rails `preload`, SQLAlchemy `selectinload`, and
Hibernate reaches with `@BatchSize`. It is the shape to prefer for a **to-many** relationship,
because each order comes back once and the customer's columns are not repeated on every row.

## One query, with a join

The other shape is lesson 5's answer:

```
shop=# SELECT c.id, c.name, o.id AS order_id, o.total FROM customers c LEFT JOIN orders o ON o.customer_id = c.id WHERE c.id IN (1, 2, 3) ORDER BY c.id, o.id;
 id |      name       | order_id | total  
----+-----------------+----------+--------
  1 | Helena Santos   |     3664 | 537.02
  1 | Helena Santos   |   258406 | 707.73
  1 | Helena Santos   |   933519 | 996.95
  2 | Bruno Costa     |    78609 | 824.88
  2 | Bruno Costa     |    82698 | 767.87
  2 | Bruno Costa     |   132296 | 480.19
  2 | Bruno Costa     |   179551 |  84.13
  2 | Bruno Costa     |   199093 | 629.38
  2 | Bruno Costa     |   315081 | 588.75
  2 | Bruno Costa     |   339910 | 410.59
  2 | Bruno Costa     |   418066 | 898.33
  2 | Bruno Costa     |   468689 | 449.14
  2 | Bruno Costa     |   469617 | 187.07
  2 | Bruno Costa     |   548309 | 248.10
  2 | Bruno Costa     |   548786 | 761.50
  2 | Bruno Costa     |   812773 | 508.08
  2 | Bruno Costa     |   813068 |  30.91
  2 | Bruno Costa     |   856379 |  75.34
  2 | Bruno Costa     |   875237 | 280.21
  3 | Fábio Carvalho |   160670 | 538.64
  3 | Fábio Carvalho |   370786 | 676.42
  3 | Fábio Carvalho |   394239 | 938.50
  3 | Fábio Carvalho |   410227 | 918.16
  3 | Fábio Carvalho |   505327 | 377.35
  3 | Fábio Carvalho |   517439 |  98.63
  3 | Fábio Carvalho |   672465 | 614.69
  3 | Fábio Carvalho |   690660 | 718.48
  3 | Fábio Carvalho |   699978 | 468.04
  3 | Fábio Carvalho |   708466 | 631.79
  3 | Fábio Carvalho |   772914 | 928.93
  3 | Fábio Carvalho |   937359 |  39.77
  3 | Fábio Carvalho |   983688 |  29.13
(32 rows)
```

One statement, one round trip, and the customer's columns are on every row of their orders —
`Bruno Costa` sixteen times. The ORM reads the rows back into one customer object holding sixteen
orders, and the repetition costs bandwidth rather than correctness.

Django's `select_related`, Rails' `eager_load`, SQLAlchemy's `joinedload`, Hibernate's
`JOIN FETCH`. It is the shape for a **to-one** relationship — each order's customer, where the
join adds a few columns to each row and repeats nothing. It is the wrong shape for a to-many one
with wide parents, where a customer with a hundred orders is a hundred copies of the customer.

Rails' `includes` picks between the two for you, and takes the join when the `WHERE` mentions the
joined table. That is convenient and it is a decision being made where you cannot see it, which
is exactly the kind of thing this lesson says to check with the log.

## Which one

| relationship | shape | why |
|---|---|---|
| to-one (an order's customer) | join | a few columns added per row, nothing repeated |
| to-many, narrow parent | either | the repetition is small |
| to-many, wide parent or many children | separate query with the set | the join would repeat the parent per child |
| filtering on the related table | join | the `WHERE` has to see both |
| several relationships at once | separate queries | joining three to-many relationships multiplies rows |

The last row is lesson 5's multiplication arriving in an ORM: joining customers to orders and to
addresses in one statement returns orders × addresses rows per customer, and a mapper that does
that silently is producing a result that is correct and enormous.

## Where to put the instruction

At the query that starts the loop, and not on the model. Most ORMs allow a relationship to be
marked as always-eager on the class, and it is tempting, because it fixes the N+1 everywhere at
once. It also loads the orders on every screen that fetches a customer, including the ones that
show a name and nothing else — lesson 10's *ask for less*, undone globally.

So the instruction belongs where the loop is: this page wants customers with their orders, that
page wants customers alone. Which is one more reason to read the emitted SQL per page rather than
per model.

## Checking it worked

The same two tools. `pg_stat_statements` after the fix shows the orders query with `calls` equal
to the number of pages rendered, not the number of customers; the log shows two statements per
page instead of fifty-one. A fix that was applied in the code and not confirmed in the count is a
fix somebody will discover was on the wrong relationship — and the count is cheaper than the
discovery.
