---
title: Iterators, and lesson 2's two averages
version: 1
---

`SUM` adds up a column. Its sibling `SUMX` takes a table and an expression, evaluates the expression
once per row of the table, and adds up the results. Every aggregation has such an **iterator**
version — `AVERAGEX`, `MINX`, `COUNTX` — and they are how DAX expresses "for each … then …".

Lesson 2 found that Lantern's average order value is one number as a ratio of sums and another as an
average of each customer's own average. In DAX, the first is the measure from three sections ago;
the second iterates over customers:

```
Net Revenue per Order = DIVIDE ( [Net Revenue], [Orders] )

Average Customer's Revenue per Order =
    AVERAGEX ( VALUES ( customers[customer_id] ), [Net Revenue per Order] )
```

(Not run.) `VALUES ( customers[customer_id] )` is the list of customers in the current context;
`AVERAGEX` evaluates the per-order measure once for each of them, in a context narrowed to that one
customer, and averages the results. The SQL for 2026 so far:

```
lantern=# SELECT round(sum(net_revenue) / count(*), 2) AS per_order
lantern-# FROM semantic.orders WHERE order_date >= '2026-01-01';
 per_order 
-----------
    153.27
(1 row)

lantern=# SELECT round(avg(per_customer), 2) AS per_customer
lantern-# FROM (SELECT customer_id, sum(net_revenue) / count(*) AS per_customer
lantern(#       FROM semantic.orders WHERE order_date >= '2026-01-01'
lantern(#       GROUP BY customer_id) AS c;
 per_customer 
--------------
       144.15
(1 row)
```

R$ 153.27 per order against R$ 144.15 for the average customer: the same gap as lesson 2, for the
same reason. Both formulas are correct and they answer different questions. **The danger is that
both are one function name away from each other**, and a report that shows "Average order value"
does not say which it computed. The measure's name should.

One detail of `AVERAGEX` is worth knowing because it moves the number: a measure referenced inside
an iterator is evaluated in the context of each row, which Microsoft's documentation calls *context
transition*. That is what made the per-customer average above work without writing a filter. It is
also why an iterator over a large table can be slow: it evaluates the measure once per row.
