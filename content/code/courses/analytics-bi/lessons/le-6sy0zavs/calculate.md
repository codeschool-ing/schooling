---
title: CALCULATE, which changes the filters
version: 1
---

Sometimes a measure needs a number from a different context than the one it is in. The share of
each region in the year's revenue needs, in every row, the revenue of **all** regions. DAX's
`CALCULATE` evaluates an expression with the filter context changed:

```
Net Revenue All Regions = CALCULATE ( [Net Revenue], ALL ( customers ) )

Share of Net Revenue = DIVIDE ( [Net Revenue], [Net Revenue All Regions] )
```

(Not run.) `ALL ( customers )` removes every filter on the customers table — the region of the row
— and keeps the others, so the year from the slicer still applies. In SQL the same thing is a window
function, whose empty `OVER ()` means "all the rows of the result":

```
lantern=# SELECT c.region,
lantern-#        round(100 * sum(o.net_revenue) / sum(sum(o.net_revenue)) OVER (), 1) AS share_pct
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-01-01'
lantern-# GROUP BY c.region ORDER BY share_pct DESC;
  region   | share_pct 
-----------+-----------
 Southeast |      74.8
 South     |      15.7
 Northeast |       8.9
 North     |       0.6
(4 rows)
```

The Southeast is three quarters of the year so far, and the North under one percent.

`CALCULATE` can also add a filter rather than remove one. A measure for one region, whatever the
matrix shows:

```
Net Revenue South = CALCULATE ( [Net Revenue], customers[region] = "South" )
```

```
lantern=# SELECT sum(o.net_revenue) AS net_revenue_south
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-01-01' AND c.region = 'South';
 net_revenue_south 
-------------------
          99133.58
(1 row)
```

R$ 99,133.58, the same figure as the South row of the matrix in the last section — but as a measure
it gives that number in every row, including the North's, because it replaces the region filter with
its own. That is the behaviour that surprises people, and it is the same rule both times: **the
filters inside `CALCULATE` win over the filters from the visual on the same column.**
