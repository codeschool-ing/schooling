---
title: RFM, and what ntile does to ties
version: 1
---

The segments of the last section are a small case of a method marketing teams have used for decades:
**RFM**, for recency, frequency and monetary value. Each customer gets a score from 1 to 5 on each of
the three, and the scores together name a segment — 5-5-5 is the best customer, 1-1-1 the most lost.

The usual recipe computes each score as a **quintile**: sort the customers and cut them into five groups
of equal size. In SQL that is `ntile(5)`, and on frequency it goes wrong in a way worth seeing:

```
lantern=# SELECT f, min(orders), max(orders), count(*) AS customers
lantern-# FROM (SELECT orders, ntile(5) OVER (ORDER BY orders) AS f
lantern(#       FROM activation.crm_contacts WHERE orders > 0) x
lantern-# GROUP BY f ORDER BY f;
 f | min | max | customers 
---+-----+-----+-----------
 1 |   1 |   1 |       530
 2 |   1 |   2 |       530
 3 |   2 |   2 |       530
 4 |   2 |   4 |       529
 5 |   4 |  16 |       529
(5 rows)
```

Five groups of 529 or 530, exactly as asked — and customers with **one order** are in score 1 *and* in
score 2. Customers with two orders are spread over scores 2, 3 and 4. `ntile` cuts at a position, not at a
value, so when 988 customers share the same number of orders it splits them wherever the 530th row
happens to fall, and which customer lands on which side depends on the order the rows come back in.

Two customers with identical histories, one scored 1 and one scored 2, may get different e-mails. Nobody
can explain why, because there is no reason.

Two ways out, and the first is the one to prefer:

- **Fixed thresholds**, like the last section's: 1 order, 2 to 3, 4 or more. Equal customers always get
  equal scores, the bands can be explained, and they do not move when next month's customers arrive.
- **Ranks that respect ties**, such as `percent_rank()`, cut into fives afterwards. Ties stay together,
  at the price of groups of unequal size.

Quintiles are fine on a value with few ties, such as revenue measured to the cent. On a count with a
handful of distinct values — orders, visits, tickets — they invent distinctions the data does not have.
