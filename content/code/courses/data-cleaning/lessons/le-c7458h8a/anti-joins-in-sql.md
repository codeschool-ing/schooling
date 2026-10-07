---
title: Finding orphans in SQL
version: 1
---

Finding the rows with no partner is called an **anti-join**, and SQL has two common ways to write
one. Both give the same answer here:

```
ana@lab:~/clean$ psql -c 'SELECT count(DISTINCT o.order_id) AS orders, count(DISTINCT o.customer_id) AS customers FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id)'
 orders | customers 
--------+-----------
    246 |        32
(1 row)

ana@lab:~/clean$ psql -c 'SELECT count(DISTINCT o.order_id) AS orders FROM raw.orders o LEFT JOIN raw.customers c ON c.customer_id = o.customer_id WHERE c.customer_id IS NULL'
 orders 
--------
    246
(1 row)
```

The first, `NOT EXISTS`, reads like the question: orders for which no customer exists. The
second, a `LEFT JOIN` followed by `WHERE c.customer_id IS NULL`, keeps every order, attaches a
customer where there is one, and then keeps only the rows where nothing was attached. **Test the
right side's key column for `NULL`, never a column that can be blank on its own**: a customer
with no e-mail would look like a missing customer if the test were on `c.email`.

Both queries count `DISTINCT o.order_id`, because `raw.orders` still holds the 25 repeated orders
and `raw.customers` its 37 repeated rows. None of the repeats happens to be an orphan, so a plain
`count(*)` would give 246 too, but **a count of rows over unclean tables is right only by luck**,
and `DISTINCT` on the key removes the luck.

There is a third way that looks the same and is not: `WHERE customer_id NOT IN (SELECT
customer_id FROM raw.customers)`. **If the subquery returns a single `NULL`, `NOT IN` returns no
rows at all**, because comparing anything with `NULL` is unknown rather than false. The customer
file has no blank codes today. The day it gets one, a query written with `NOT IN` reports zero
orphans and looks like good news. Prefer `NOT EXISTS`, which has no such trap.
