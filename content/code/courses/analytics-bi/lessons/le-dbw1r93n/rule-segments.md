---
title: Segments from two rules
version: 1
---

The simplest segments come from rules you can say aloud. Lesson 7's model already has two: `health`,
from how recently a customer ordered, and `orders`, how often. Cut each into three bands and cross them:

```
lantern=# SELECT health,
lantern-#        CASE WHEN orders = 1 THEN '1 order'
lantern-#             WHEN orders <= 3 THEN '2-3 orders'
lantern-#             ELSE '4+ orders' END AS frequency,
lantern-#        count(*) AS customers, sum(net_revenue) AS net_revenue
lantern-# FROM activation.crm_contacts
lantern-# WHERE orders > 0
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 health  | frequency  | customers | net_revenue 
---------+------------+-----------+-------------
 active  | 1 order    |       306 |    42047.51
 active  | 2-3 orders |       340 |   109079.02
 active  | 4+ orders  |       321 |   330774.49
 at risk | 1 order    |       209 |    29275.05
 at risk | 2-3 orders |       227 |    78446.82
 at risk | 4+ orders  |       173 |   153117.26
 lapsed  | 1 order    |       473 |    56773.19
 lapsed  | 2-3 orders |       416 |   122897.05
 lapsed  | 4+ orders  |       183 |   124346.01
(9 rows)
```

Nine segments, each a sentence. Three of them carry most of the decisions:

- **Active, four or more orders**: 321 customers, 12% of the base, and R$ 330,774.49 — 32% of all the
  revenue the shop has made. These are the ones not to lose; they need no discount, and a programme that
  gives them one is money given to people who would have bought anyway.
- **At risk, four or more orders**: 173 customers who used to order often and have gone quiet for 45 to
  120 days. R$ 153,117.26 between them, about R$ 885 each. This is lesson 8's win-back list with the
  office filter removed, and the segment where a phone call is most likely to pay for itself.
- **Lapsed, one order**: 473 customers, the largest group, and R$ 56,773.19. One purchase, more than 120
  days ago. Many came for a promotion, and it is the segment where most effort is wasted.

Two properties make these segments useful rather than merely tidy. **The bands mean something**: 45 days is
where lesson 2 found three gaps in four between orders end, and *one order* is a real line — a customer who
never came back is a different case from one who came back once. And **every customer falls in exactly
one cell**, so the nine add up to the 2,648 customers with an order, and nobody is counted twice or lost.
