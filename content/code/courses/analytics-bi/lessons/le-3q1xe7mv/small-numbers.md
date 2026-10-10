---
title: A rate on four orders
version: 1
---

Refund rates by region, over the shop's whole life:

```
lantern=# SELECT c.region, count(*) AS orders,
lantern-#        count(*) FILTER (WHERE o.status = 'refunded') AS refunded,
lantern-#        round(100.0 * count(*) FILTER (WHERE o.status = 'refunded') / count(*), 1) AS refund_pct
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# GROUP BY 1 ORDER BY 2 DESC;
  region   | orders | refunded | refund_pct 
-----------+--------+----------+------------
 Southeast |   5437 |      201 |        3.7
 South     |   1126 |       39 |        3.5
 Northeast |    486 |       13 |        2.7
 North     |     49 |        4 |        8.2
(4 rows)
```

Read as a ranking, the North refunds more than twice as often as anywhere else: 8.2% against 3.7%. Read
as counts, the North has had 49 orders and four refunds. **One more refund would make it 10.2%; one fewer,
6.1%.** A rate is the more convincing the less it should be trusted, because a small denominator
produces exactly the extreme values that make a headline.

Lesson 6 met the same thing on a dashboard, as a region with five orders in a month. The analyst's
version of the rule is stronger than "show the count":

- **Decide a minimum before reading the ranking.** A rate below the minimum is not shown as a number,
  or is shown greyed with its count, and the minimum is written on the page.
- **Look at a range, not a point.** With 4 refunds in 49, the standard error of lesson 9 is
  √(0.082 × 0.918 / 49), about 3.9 points. The North's rate is "somewhere between about 0% and 16%",
  which includes the Southeast's 3.7%.
- **Ask whether the difference would survive a month.** If next month's North has 2 refunds in 5 orders,
  it is 40%, and nobody should change a policy on that either.

The question that catches it: **how many things is this rate counting?**
