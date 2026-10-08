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
   id   | customer_id |           placed_at           | total  
--------+-------------+-------------------------------+--------
 867901 |           1 | 2024-02-01 19:45:14.879823+00 | 645.81
 436232 |           1 | 2024-03-20 14:06:59.047487+00 | 248.10
 832622 |           1 | 2024-04-03 05:16:39.364248+00 | 292.93
 563685 |           1 | 2024-05-12 06:31:09.597037+00 | 950.55
 712515 |           1 | 2024-06-19 20:24:34.119482+00 | 999.09
 106558 |           1 | 2024-10-24 13:18:18.94516+00  | 378.71
 376517 |           1 | 2025-03-01 12:22:17.35475+00  | 449.14
 186406 |           1 | 2025-03-13 08:14:07.577697+00 | 241.28
  83957 |           1 | 2025-04-01 08:36:51.409198+00 | 824.88
 561192 |           1 | 2025-05-18 15:20:10.148928+00 | 826.20
 174320 |           1 | 2025-07-28 07:33:10.682282+00 | 629.38
 634580 |           1 | 2025-08-13 19:55:45.983218+00 | 508.08
 973786 |           2 | 2023-11-25 23:44:59.843629+00 | 402.98
 153988 |           2 | 2024-02-05 13:20:55.311275+00 | 362.49
 377213 |           2 | 2024-02-14 05:58:51.408678+00 | 187.07
 750331 |           2 | 2024-05-30 12:41:13.21633+00  | 130.32
 808345 |           2 | 2024-06-30 19:37:46.382061+00 | 661.96
 817860 |           2 | 2024-08-11 14:43:12.612129+00 | 584.30
 906859 |           2 | 2024-08-14 19:10:22.97878+00  | 431.19
  66505 |           2 | 2025-04-07 09:18:44.349303+00 | 706.37
 681428 |           2 | 2025-04-27 15:58:35.762079+00 | 280.21
 261311 |           2 | 2025-04-28 06:47:29.029807+00 | 588.75
 529349 |           3 | 2023-09-27 13:43:57.406336+00 | 614.69
 733286 |           3 | 2023-10-19 15:14:47.740549+00 | 359.85
 263511 |           3 | 2024-01-15 10:05:51.665555+00 | 398.62
 115453 |           3 | 2024-06-11 18:02:51.326442+00 | 473.14
  38758 |           3 | 2024-09-07 23:17:18.02898+00  | 254.42
 818551 |           3 | 2024-09-29 21:18:52.879204+00 | 494.03
 298176 |           3 | 2024-11-01 04:43:50.533645+00 | 343.01
 789889 |           3 | 2024-12-27 14:51:54.473518+00 | 840.21
 795003 |           3 | 2025-01-17 23:10:49.224958+00 | 961.90
 135774 |           3 | 2025-03-14 15:27:50.707643+00 | 700.78
 881393 |           3 | 2025-06-24 11:11:44.245599+00 | 533.82
 665173 |           3 | 2025-08-25 05:04:37.836811+00 | 616.18
(34 rows)
```

Two statements for the page instead of fifty-one, whatever N is. The plan is the one lesson 10
would predict:

```
shop=# EXPLAIN ANALYZE SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=45.13..443.26 rows=109 width=22) (actual time=0.045..0.214 rows=95 loops=1)
   Recheck Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
   Heap Blocks: exact=93
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..45.08 rows=109 width=0) (actual time=0.022..0.022 rows=95 loops=1)
         Index Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
 Planning Time: 0.566 ms
 Execution Time: 0.271 ms
(7 rows)
```

A bitmap scan through the index on `customer_id`, once, for all ten ids — 95 rows in a quarter of
a millisecond. Fifty ids is the same shape with a longer array, and a hundred thousand ids is the
point at which the ORM sends the array in chunks.

This is what Django calls `prefetch_related`, Rails `preload`, SQLAlchemy `selectinload`, and
Hibernate reaches with `@BatchSize`. It is the shape to prefer for a **to-many** relationship,
because each order comes back once and the customer's columns are not repeated on every row.

## One query, with a join

The other shape is lesson 5's answer:

```
shop=# SELECT c.id, c.name, o.id AS order_id, o.total FROM customers c LEFT JOIN orders o ON o.customer_id = c.id WHERE c.id IN (1, 2, 3) ORDER BY c.id, o.id;
 id |     name     | order_id | total  
----+--------------+----------+--------
  1 | Igor Fontes  |    83957 | 824.88
  1 | Igor Fontes  |   106558 | 378.71
  1 | Igor Fontes  |   174320 | 629.38
  1 | Igor Fontes  |   186406 | 241.28
  1 | Igor Fontes  |   376517 | 449.14
  1 | Igor Fontes  |   436232 | 248.10
  1 | Igor Fontes  |   561192 | 826.20
  1 | Igor Fontes  |   563685 | 950.55
  1 | Igor Fontes  |   634580 | 508.08
  1 | Igor Fontes  |   712515 | 999.09
  1 | Igor Fontes  |   832622 | 292.93
  1 | Igor Fontes  |   867901 | 645.81
  2 | Ana Alves    |    66505 | 706.37
  2 | Ana Alves    |   153988 | 362.49
  2 | Ana Alves    |   261311 | 588.75
  2 | Ana Alves    |   377213 | 187.07
  2 | Ana Alves    |   681428 | 280.21
  2 | Ana Alves    |   750331 | 130.32
  2 | Ana Alves    |   808345 | 661.96
  2 | Ana Alves    |   817860 | 584.30
  2 | Ana Alves    |   906859 | 431.19
  2 | Ana Alves    |   973786 | 402.98
  3 | Elisa Fontes |    38758 | 254.42
  3 | Elisa Fontes |   115453 | 473.14
  3 | Elisa Fontes |   135774 | 700.78
  3 | Elisa Fontes |   263511 | 398.62
  3 | Elisa Fontes |   298176 | 343.01
  3 | Elisa Fontes |   529349 | 614.69
  3 | Elisa Fontes |   665173 | 616.18
  3 | Elisa Fontes |   733286 | 359.85
  3 | Elisa Fontes |   789889 | 840.21
  3 | Elisa Fontes |   795003 | 961.90
  3 | Elisa Fontes |   818551 | 494.03
  3 | Elisa Fontes |   881393 | 533.82
(34 rows)
```

One statement, one round trip, and the customer's columns are on every row of their orders —
`Igor Fontes` twelve times. The ORM reads the rows back into one customer object holding twelve
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
