---
title: Dimensions, and the levels inside one
version: 1
---

A **dimension** is an attribute you group a measure by. Lantern's customers carry three — the
state they live in, the segment, and the channel they arrived through — and the date of the order
is a fourth that every table has. Most of the work with a dimension is not in the grouping, which
is one `GROUP BY`, but in agreeing what its values are.

## A dimension often has levels

States roll up into Brazil's five regions, and a report for the board wants regions while a report
for logistics wants states. The rollup is a **hierarchy**, and it has to be written down too:

```sql
SELECT CASE c.state WHEN 'SP' THEN 'Southeast' WHEN 'RJ' THEN 'Southeast'
                    WHEN 'MG' THEN 'Southeast' WHEN 'PR' THEN 'South'
                    WHEN 'RS' THEN 'South'     WHEN 'BA' THEN 'Northeast'
                    WHEN 'AC' THEN 'North' END AS region,
       count(DISTINCT c.customer_id) AS customers,
       round(sum(r.net_cents) / 100.0, 2) AS net_brl
FROM order_revenue r JOIN customers c USING (customer_id)
WHERE r.status = 'paid' AND r.customer_id <> 1
GROUP BY 1 ORDER BY 3 DESC;
```

```
lantern=# SELECT CASE c.state WHEN 'SP' THEN 'Southeast' WHEN 'RJ' THEN 'Southeast'
lantern-#                     WHEN 'MG' THEN 'Southeast' WHEN 'PR' THEN 'South'
lantern-#                     WHEN 'RS' THEN 'South'     WHEN 'BA' THEN 'Northeast'
lantern-#                     WHEN 'AC' THEN 'North' END AS region,
lantern-#        count(DISTINCT c.customer_id) AS customers,
lantern-#        round(sum(r.net_cents) / 100.0, 2) AS net_brl
lantern-# FROM order_revenue r JOIN customers c USING (customer_id)
lantern-# WHERE r.status = 'paid' AND r.customer_id <> 1
lantern-# GROUP BY 1 ORDER BY 3 DESC;
  region   | customers |  net_brl  
-----------+-----------+-----------
 Southeast |      2008 | 810624.75
 South     |       417 | 186736.44
 Northeast |       183 |  84818.42
 North     |        16 |   5761.78
(4 rows)
```

The Southeast is most of the shop: 2,008 of the customers who paid, and R$ 810,624.75 of net
revenue. Acre, the only state of the North in the data, has 16.

**The mapping inside that `CASE` is a definition like any other.** The day somebody writes a
second report with a `CASE` of their own and puts Bahia in a different region, the two reports
disagree about the Northeast and both look right. Lesson 3 moves mappings like this one into a
table, so that every query reads the same one.

## Which value, and when

A customer who moved from Paraná to São Paulo in March has two states: the one they had when they
ordered in February, and the one they have now. Grouping February's orders by the customer's
current state moves them to São Paulo after the fact, and last year's report changes every time
somebody updates an address. Lantern's table keeps only one state per customer, so the question
does not arise here — but it does in every real shop, and whether a dimension shows its value **at
the time of the event or now** is part of its definition. Modelling both is the subject of slowly
changing dimensions, in `warehouse-modeling`.
