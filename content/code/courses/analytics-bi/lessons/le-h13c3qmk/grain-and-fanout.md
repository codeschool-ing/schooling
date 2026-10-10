---
title: Grain, and the join that multiplies
version: 1
---

Every fact table has a **grain**, and lesson 1 asked you to write it down the first time you
checked it. Here is why. A measure belongs to the grain where it was recorded: a discount is a
property of an **order**, so it lives in `orders`, once per order. Join `orders` to `order_lines`
and each order appears once per line — and its discount with it.

```
lantern=# SELECT sum(o.discount) AS discount_joined
lantern-# FROM semantic.orders o JOIN semantic.order_lines l USING (order_id)
lantern-# WHERE o.order_date BETWEEN '2026-01-01' AND '2026-03-31';
 discount_joined 
-----------------
        46481.30
(1 row)

lantern=# SELECT sum(discount) AS discount_alone
lantern-# FROM semantic.orders
lantern-# WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
 discount_alone 
----------------
       23768.58
(1 row)
```

The same quarter, the same discounts, and the first query reports twice the money. **Nothing
failed.** The join did exactly what joins do: an order with three lines became three rows, and
`sum` added its discount three times. This is called a **fan-out**, and it produces numbers that
are too large by an amount that depends on how many lines orders happen to have — which is why it
can survive in a dashboard for months, wrong by a factor nobody can guess.

Three rules prevent it, and the layer exists partly to apply them so nobody else has to:

- **A measure is summed at its own grain.** Discount and net revenue are summed from `orders`;
  quantity is summed from `order_lines`.
- **To combine two grains, aggregate the finer one first.** If a question needs revenue and the
  number of bags per order, sum the lines per order in a subquery, then join one row per order to
  `orders`. That is exactly how the `orders` view computes `gross` from its lines.
- **Join from the fact to dimensions, not from fact to fact.** A dimension has one row per key, so
  a join to it never multiplies the fact. `orders` joined to `customers` keeps one row per order.

A tool that lets anybody join anything to anything will produce fan-outs for somebody. The layer's
job is to make the safe paths the obvious ones — and the products named at the end of this lesson
exist largely to make the unsafe ones impossible.
