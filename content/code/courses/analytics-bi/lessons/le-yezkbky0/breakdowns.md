---
title: Breakdowns, and the region with five orders
version: 1
---

The third question on the list — where the money comes from — is a breakdown, and a breakdown has a
trap that grows with the number of pieces. May 2026 by region:

```
lantern=# SELECT c.region, count(*) AS orders, sum(o.net_revenue) AS net_revenue
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-05-01' AND o.order_date < '2026-06-01'
lantern-# GROUP BY c.region ORDER BY net_revenue DESC;
  region   | orders | net_revenue 
-----------+--------+-------------
 Southeast |    657 |   106548.18
 South     |    139 |    24688.47
 Northeast |     54 |     8094.39
 North     |      5 |      766.02
(4 rows)
```

The Southeast is three quarters of the month. The North is five orders and R$ 766.02. A dashboard that
shows each region's change on last month in a tile of the same size gives those five orders the same
weight on the page as the Southeast's 657 — and small numbers move a lot:

```
lantern=# SELECT to_char(date_trunc('month', o.order_date), 'YYYY-MM') AS month, count(*) AS orders,
lantern-#        sum(o.net_revenue) AS net_revenue
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE c.region = 'North' AND o.order_date >= '2026-01-01'
lantern-# GROUP BY 1 ORDER BY 1;
  month  | orders | net_revenue 
---------+--------+-------------
 2026-01 |      6 |      424.51
 2026-02 |      7 |     1140.91
 2026-03 |      4 |      396.30
 2026-04 |      5 |      406.10
 2026-05 |      5 |      766.02
 2026-06 |      3 |      622.86
(6 rows)
```

The North went from R$ 424.51 in January to R$ 1,140.91 in February, an increase of 169%, on seven
orders. A single office ordering once can do that. **A percentage change on a handful of events is
noise wearing the clothes of a finding**, and lesson 10 returns to it as one of the commonest ways a
true number misleads.

What a dashboard can do about it:

- **Show the count beside the rate.** "+169% (7 orders)" reads very differently from "+169%".
- **Group the small pieces.** Below some number of orders, a region joins "other regions", and the
  rule for that is written on the page.
- **Sort by size, not by name.** The breakdown above is sorted by net revenue, so the eye meets the
  Southeast first and the North last, which is their order of importance to the business.
