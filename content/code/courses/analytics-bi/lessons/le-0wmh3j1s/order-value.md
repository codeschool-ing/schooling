---
title: Order value, and the shape of its distribution
version: 1
---

Lantern's tables do not store what an order was worth. An order's lines carry a quantity and a
unit price, so its value is their sum — and a number you compute every time is one you should
compute once, in one place. A **view** is a saved query that behaves like a table:

```sql
CREATE VIEW order_totals AS
SELECT o.order_id, o.customer_id, o.ordered_at, o.status, o.discount_pct,
       sum(l.quantity * l.unit_cents) AS gross_cents
FROM orders o
JOIN order_lines l USING (order_id)
GROUP BY o.order_id;
```

Type it into `psql lantern`. It is one row per order, the grain of `orders`, with the value
before any discount in cents. **Money is kept in whole cents** — `11990` is R$ 119.90 —
because a sum of fractions of a real in floating point drifts by fractions of a cent, and a
finance team notices.

## The shape, before the average

The first thing to know about a numeric column is its **distribution**: how many rows fall at
each value. A histogram is that count per range of values, and SQL can draw a crude one.
`width_bucket` puts each value into one of eight bands of R$ 50 between 0 and R$ 400, and
`repeat` prints one `#` per forty orders:

```
lantern=# SELECT (width_bucket(gross_cents, 0, 40000, 8) - 1) * 50 AS from_brl,
lantern-#        count(*), repeat('#', count(*)::int / 40) AS orders
lantern-# FROM order_totals GROUP BY 1 ORDER BY 1;
 from_brl | count |                       orders                       
----------+-------+----------------------------------------------------
        0 |  2012 | ##################################################
       50 |  1581 | #######################################
      100 |  1294 | ################################
      150 |   769 | ###################
      200 |   377 | #########
      250 |   337 | ########
      300 |   141 | ###
      350 |   121 | ###
      400 |   470 | ###########
(9 rows)
```

Read it from the top. The tallest band is the first: 2,012 orders under R$ 50. Each band after
it is shorter, down to 121 orders between R$ 350 and R$ 400 — and then the last row, which
`width_bucket` uses for **everything at R$ 400 or above**, jumps back up to 470.

Two shapes are in that picture. The long slope down to the right is a **right-skewed**
distribution: most orders are small, a few are large, and there is no symmetry around a middle.
And the jump at the end says the slope does not simply fade away: there is a second group of
orders, large enough to fill the catch-all band, that the bands do not resolve. Two sections on, this
lesson finds out who placed them.

**A histogram is a question, not an answer.** It tells you where to look next: here, at the
small orders that make up most of the shop, and at the group above R$ 400 that does not belong to
the slope.
