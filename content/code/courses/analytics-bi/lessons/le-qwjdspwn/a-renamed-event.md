---
title: What a renamed event does to a funnel
version: 1
---

The checks of the last section are about events. What the business sees is the funnel built from them,
and here is that day's, by device, counted the way a dashboard counts it — sessions reaching each step
of the plan:

```
lantern=# SELECT p.step, p.event,
lantern-#        count(DISTINCT i.session_id) FILTER (WHERE i.device = 'desktop') AS desktop,
lantern-#        count(DISTINCT i.session_id) FILTER (WHERE i.device = 'mobile') AS mobile
lantern-# FROM tracking.plan p LEFT JOIN tracking.incoming i USING (event)
lantern-# GROUP BY p.step, p.event ORDER BY p.step;
 step |    event     | desktop | mobile 
------+--------------+---------+--------
    1 | visit        |      75 |    138
    2 | product_view |      41 |     55
    3 | add_to_cart  |      16 |      0
    4 | checkout     |       8 |     12
    5 | purchase     |       6 |      8
(5 rows)
```

On desktop the funnel narrows the way it always has. On mobile, **not one session added anything to a
cart**, and yet twelve reached checkout and eight bought. Read naively, the cart step converts 0% and
the checkout step converts from nothing. On a dashboard of conversion rates, mobile's
product-to-cart rate falls from its usual level to zero on the day of a release, and somebody spends a
morning looking for the bug in the cart.

There is no bug in the cart. There are 19 sessions that added to their cart and said so under a name the
funnel does not look for. **The funnel is only as good as the event names it counts**, and nothing in a
funnel query can tell a step nobody took from a step whose name changed.

This is the case for running the checks *before* the day's events are loaded, rather than reading the
funnel and wondering. A failed check on the morning of 18 June says "`addToCart` is not in the plan"; a
funnel says "mobile customers stopped using the cart". The first is a fix to the app or to the plan,
agreed between two people. The second is a meeting.

Two fixes are possible, and the plan decides which. If `add_to_cart` is the agreed name, the app is
wrong and is fixed, and the staged events are renamed before loading. If the company decides
`addToCart` is the better name, the plan changes first, and every query that counts the old name changes
with it. What is not a fix is a `CASE` in one dashboard's query that treats both names as the same,
because the next dashboard will not have it.
