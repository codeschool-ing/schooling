---
title: The customers who are not there any more
version: 1
---

A claim heard in many shops: *our oldest customers are our best*. Lantern's customers who first ordered
in its first quarter, January to March 2025, split by whether they are still active:

```
lantern=# WITH c AS (
lantern(#   SELECT customer_id, min(order_date) AS first_order, max(order_date) AS last_order,
lantern(#          count(*) FILTER (WHERE status = 'paid') AS paid_orders
lantern(#   FROM semantic.orders GROUP BY customer_id),
lantern-# asof AS (SELECT max(order_date) AS day FROM semantic.orders)
lantern-# SELECT last_order >= asof.day - 45 AS still_active,
lantern-#        count(*) AS customers, round(avg(paid_orders), 2) AS avg_paid_orders
lantern-# FROM c, asof
lantern-# WHERE first_order < '2025-04-01'
lantern-# GROUP BY 1 ORDER BY 1;
 still_active | customers | avg_paid_orders 
--------------+-----------+-----------------
 f            |        65 |            3.52
 t            |         3 |           11.67
(2 rows)
```

The three still active have made 11.67 paid orders each. A report that looked only at active customers —
the ones in the CRM's *active* list, the ones a dashboard of "current customers" shows — would say that
the early customers average almost twelve orders. **The 65 who left are not in that report**, and they
averaged 3.52.

That is **survivorship bias**: drawing a conclusion from the members of a group who survived some filter,
as if they were the whole group. The filter here is "still active", and it selected exactly the customers
who order often. The conclusion "the longer they stay, the more they order" is backwards — they stayed
*because* they order; most of their generation did not.

It turns up wherever a list has been filtered by the outcome:

- **Active customers only.** Every average over today's customers excludes everybody who left, and the
  leavers are the ones a retention question is about.
- **Successful campaigns only.** A deck of the three campaigns that worked, from the twelve that ran.
- **Answers to a satisfaction survey.** The people who answer are not the people who left quietly.

The cohort grid of lesson 9 is the defence built in: it starts from everybody who arrived, and counts who
is left, instead of starting from who is left.

The question that catches it: **who was removed from this list before I saw it, and by what?**
