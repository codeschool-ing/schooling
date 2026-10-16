---
title: Writing the arithmetic once
version: 1
---

The three queries in the last section each computed the discount inline, and the same expression
written three times is three chances to write it differently. Lesson 1 put the order's gross value
in a view; this one puts the discount and the net value beside it:

```sql
CREATE VIEW order_revenue AS
SELECT order_id, customer_id, ordered_at, status, gross_cents,
       gross_cents * discount_pct / 100 AS discount_cents,
       gross_cents - gross_cents * discount_pct / 100 AS net_cents
FROM order_totals;
```

Type it into `psql lantern`. It builds on `order_totals`, so that view has to exist; if you reset
the shop since lesson 1, create it again first.

```
lantern=# CREATE VIEW order_revenue AS
lantern-# SELECT order_id, customer_id, ordered_at, status, gross_cents,
lantern-#        gross_cents * discount_pct / 100 AS discount_cents,
lantern-#        gross_cents - gross_cents * discount_pct / 100 AS net_cents
lantern-# FROM order_totals;
CREATE VIEW
```

Three orders, to see what it does:

```
lantern=# SELECT order_id, status, gross_cents, discount_cents, net_cents
lantern-# FROM order_revenue WHERE order_id IN (5001, 5002, 5003);
 order_id | status | gross_cents | discount_cents | net_cents 
----------+--------+-------------+----------------+-----------
     5001 | paid   |       12990 |              0 |     12990
     5002 | paid   |       29610 |           4441 |     25169
     5003 | paid   |      112790 |          16918 |     95872
(3 rows)
```

Order 5001 had no discount, so its net value is its gross. Order 5002 is an office order with 15%
off: 15% of 29,610 cents is 4,441.5, and the view says 4,441. **Integer division throws the half
cent away**, so the customer is charged half a cent more than the exact arithmetic says. Which way
to round is a business rule, and the point is that it is now written in one place: if finance
decides the shop rounds the other way, one line changes and every number built on the view moves
together.

From now on, "net revenue" in this course means `sum(net_cents)` over orders whose status is
`paid`, without customer 1. That sentence is a definition, and the rest of this lesson takes it
apart to see what it is made of.
