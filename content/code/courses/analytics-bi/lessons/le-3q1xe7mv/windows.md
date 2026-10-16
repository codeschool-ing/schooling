---
title: Choosing where a comparison starts
version: 1
---

How much did Lantern grow to May 2026? It depends on what May is compared with:

```
lantern=# WITH m AS (
lantern(#   SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
lantern(#   FROM semantic.orders GROUP BY 1)
lantern-# SELECT b.month AS compared_with, b.net_revenue AS then,
lantern-#        may.net_revenue AS may_2026,
lantern-#        round(100.0 * (may.net_revenue - b.net_revenue) / b.net_revenue, 1) AS change_pct
lantern-# FROM m b, m may
lantern-# WHERE may.month = '2026-05-01'
lantern-#   AND b.month IN ('2025-05-01', '2025-11-01', '2026-04-01')
lantern-# ORDER BY b.month;
 compared_with |   then    | may_2026  | change_pct 
---------------+-----------+-----------+------------
 2025-05-01    |  21811.31 | 140097.06 |      542.3
 2025-11-01    |  90630.78 | 140097.06 |       54.6
 2026-04-01    | 119821.78 | 140097.06 |       16.9
(3 rows)
```

All three are correct and come from the same table. Against May 2025, **+542.3%**: a year ago the shop
was small. Against November 2025, **+54.6%**: Black Friday's peak. Against April 2026, **+16.9%**: last
month. A report that wanted growth to look spectacular would pick the first; one that wanted to say the
campaign's peak was beaten would pick the second. The reverse works too: December 2025 against
November is a fall of 17%, in a shop that grew in almost every other month.

Choosing a window is unavoidable, so the defence is not to avoid it but to **choose it before looking
at the result**, for a reason that has to do with the question:

- **Month against the same month a year before** removes the seasons, which is why it is the default for
  a business with a Black Friday. It needs the business to have been the same kind of business a year
  ago, which for Lantern in May 2025 it barely was.
- **Month against the month before** answers "is it still moving?", and suffers from every season.
- **Against a peak or a trough** is almost never the right question, and is exactly the comparison that
  gets chosen after looking.

Better still, **show the series** instead of a single comparison, as the dashboard of lesson 6 did with
twelve months of bars. A series cannot be cherry-picked, because every start is visible.

The question that catches it: **would the conclusion survive a different starting month?**
