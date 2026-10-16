---
title: Ratios, and which average you meant
version: 1
---

Many of the metrics a business watches are ratios: revenue per order, orders per customer,
conversion as purchases per visit. A ratio has two parts, and it can be averaged in two ways that
give two different numbers. Lantern's average order value, asked both ways:

```
lantern=# SELECT round(sum(gross_cents) / count(*) / 100.0, 2) AS per_order
lantern-# FROM order_totals WHERE customer_id <> 1;
 per_order 
-----------
    170.33
(1 row)

lantern=# SELECT round(avg(customer_avg) / 100.0, 2) AS per_customer
lantern-# FROM (SELECT customer_id, avg(gross_cents) AS customer_avg
lantern(#       FROM order_totals WHERE customer_id <> 1
lantern(#       GROUP BY customer_id) AS c;
 per_customer 
--------------
       156.10
(1 row)
```

The first is the **ratio of sums**: all the money divided by all the orders, R$ 170.33. The second
is the **average of ratios**: each customer's own average order, then the average of those, R$
156.10. The difference is not rounding. In the first, a customer with forty orders weighs forty
times as much as a customer with one; in the second, each customer weighs the same. Offices order
often and in large amounts, so they pull the first number up more than the second.

Both are legitimate, and they answer different questions:

| | answers | weights |
|---|---|---|
| ratio of sums | what does an order bring in, on average? | each order equally |
| average of ratios | what does a typical customer spend per order? | each customer equally |

**The definition has to say which.** A tool that averages a column of per-customer ratios, or a
dashboard that averages a column of daily conversion rates, computes the second kind whether or
not anybody meant it to. Lesson 4 meets the same trap in Power BI's formula language, where it is
one function name away.

A rule of thumb that is right far more often than not: when the metric is "the business's" — the
shop's conversion, the shop's order value — compute the ratio of sums, by summing the numerator
and the denominator separately and dividing once at the end.
