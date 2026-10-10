---
title: Filter context, which is a WHERE you did not write
version: 1
---

A measure has no fixed value. `[Net Revenue]` is a different number in every cell of every visual,
and what decides which number is the **filter context**: the set of filters in force for that cell.

Put `[Net Revenue]` in a matrix with `customers[region]` on the rows, and a slicer on the page set
to the year 2026. Power BI evaluates the measure five times — once per region, once for the total
— and each time the filter context is different:

| cell | filters in force |
|---|---|
| North | calendar year 2026, region = North |
| South | calendar year 2026, region = South |
| … | … |
| Total | calendar year 2026 |

The filters arrive on `customers` and `calendar` and travel along the relationships to `orders`,
where `SUM` adds up whatever rows survived. In SQL, that whole matrix is one query you could have
written in lesson 2:

```
lantern=# SELECT c.region, sum(o.net_revenue) AS net_revenue
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-01-01'
lantern-# GROUP BY ROLLUP (c.region)
lantern-# ORDER BY c.region NULLS LAST;
  region   | net_revenue 
-----------+-------------
 North     |     3756.70
 Northeast |    56003.78
 South     |    99133.58
 Southeast |   471046.32
           |   629940.38
(5 rows)
```

**That is all filter context is**: the `WHERE` comes from the slicer, the `GROUP BY` from the rows of
the matrix, and the join from the relationships. The DAX measure says only `SUM`; the visual supplies
the rest. The total is not the visual adding up the cells. It is the measure evaluated
again with the region filter removed, which is why, for a measure that is not a plain sum, a total
can look as though it does not add up and still be right.

The practical consequence: **a measure is written once and gives the right answer in every visual**,
because it never says which rows it covers. That is also why it is hard to read: the formula is short
because the context is invisible.
