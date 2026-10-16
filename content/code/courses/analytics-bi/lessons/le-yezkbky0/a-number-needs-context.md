---
title: A number needs context
version: 1
---

Here is the most important number on Lantern's page:

```
lantern=# SELECT sum(net_revenue) AS net_revenue_may
lantern-# FROM semantic.orders
lantern-# WHERE order_date >= '2026-05-01' AND order_date < '2026-06-01';
 net_revenue_may 
-----------------
       140097.06
(1 row)
```

R$ 140,097.06 of net revenue in May 2026. Is that good? The number cannot say. **A number on its own
is not information; a number beside the right comparison is.** Three comparisons answer most
questions, and a tile should carry at least one:

```
lantern=# SELECT sum(net_revenue) FILTER (WHERE order_date >= '2026-05-01' AND order_date < '2026-06-01') AS may_2026,
lantern-#        sum(net_revenue) FILTER (WHERE order_date >= '2026-04-01' AND order_date < '2026-05-01') AS april_2026,
lantern-#        sum(net_revenue) FILTER (WHERE order_date >= '2025-05-01' AND order_date < '2025-06-01') AS may_2025
lantern-# FROM semantic.orders;
 may_2026  | april_2026 | may_2025 
-----------+------------+----------
 140097.06 |  119821.78 | 21811.31
(1 row)
```

| compared with | change | what it answers | the trap |
|---|---|---|---|
| the previous month | +16.9% | is it moving? | seasonality: December against November says more about Christmas than about the shop |
| the same month last year | more than six times | is it growing? | a young business; lesson 4 called it measuring the shop's birth |
| the target | the next sections | is it where we said it would be? | a target set badly makes every month look good or bad |

None of the three is right in general. Which one belongs on the tile depends on the question it
answers, and the question is on the list from two sections ago: *is the month on track — against last
month, and against the target?* So the tile carries those two, and the year-on-year figure, which
for Lantern would be enormous and meaningless, stays off.

**A change needs its base.** "+16.9%" alone hides whether it came from R$ 100 or R$ 100,000; the tile
shows the number large and the comparison small beside it, and a reader can always reconstruct the
other.
