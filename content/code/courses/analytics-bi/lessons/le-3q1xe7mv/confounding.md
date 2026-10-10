---
title: The discount that seems to make people spend
version: 1
---

Lesson 1 met this confounder as a correlation of 0.271, in an exploratory query nobody outside the data
team would see. Here it is in the form in which it reaches a slide. Marketing wants to know whether
discounts make customers buy more, and the answer seems to come at once:

```
lantern=# SELECT discount > 0 AS discounted, count(*) AS orders, round(avg(gross), 2) AS avg_gross
lantern-# FROM semantic.orders WHERE status = 'paid'
lantern-# GROUP BY 1 ORDER BY 1;
 discounted | orders | avg_gross 
------------+--------+-----------
 f          |   4801 |    114.30
 t          |   2040 |    281.72
(2 rows)
```

Orders with a discount have an average gross value of R$ 281.72; orders without, R$ 114.30. **Discounted
baskets are 2.5 times larger.** That is a much more persuasive sentence than *r* = 0.271, which is
exactly why it is more dangerous: it is a ratio of two averages, everybody understands it, and the
proposal writes itself — discount more.

Split by customer segment, as lesson 1 did:

```
lantern=# SELECT c.segment, o.discount > 0 AS discounted, count(*) AS orders,
lantern-#        round(avg(o.gross), 2) AS avg_gross
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.status = 'paid'
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 segment | discounted | orders | avg_gross 
---------+------------+--------+-----------
 home    | f          |   4801 |    114.30
 home    | t          |   1383 |    112.87
 office  | t          |    657 |    637.16
(3 rows)
```

Every office order has a discount, the 15% offices always get, and office orders are large because
offices buy in quantity. Among home customers, the only group where orders come both with and without a
discount, the discounted ones average R$ 112.87 and the others R$ 114.30: **no difference at all.** The
segment causes both the discount and the large basket, and the 2.5 was a comparison of offices with
homes, labelled discounted against full-price.

What makes a confounder hard to see in a report is that the split which reveals it is one nobody asked
for. The question was about discounts; the answer lives in a column about customers. So the habit is not
"split by segment" but **ask what else differs between the two groups, before trusting the difference**.

Splitting by every candidate is the weak defence: there is always one more column. The strong one is the
holdout of lesson 9. If a test gives the discount to customers chosen at random, then segment, region
and everything else are spread equally over both groups by construction, and whatever difference
remains is the discount's.

The question that catches it: **what else is different between the two groups I am comparing?**
