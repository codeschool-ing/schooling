---
title: Which way a filter travels
version: 1
---

A model with single-direction relationships answers most questions correctly and one kind wrongly
in a way that surprises everybody once. Put a card showing `[Orders]` on a page with a slicer on
`products[product]`, and choose *Hand Grinder*.

The filter starts on `products` and travels along the relationship to `order_lines`, the many side:
only grinder lines survive. It does not travel on from `order_lines` to `orders`, because that
relationship points the other way — its one side is `orders`. So `orders` is unfiltered, and the card
shows every order in the shop. In SQL, the two answers:

```
lantern=# SELECT count(*) AS orders_with_a_grinder
lantern-# FROM semantic.orders o
lantern-# WHERE EXISTS (SELECT 1 FROM semantic.order_lines l JOIN semantic.products p USING (product_id)
lantern(#               WHERE l.order_id = o.order_id AND p.product = 'Hand Grinder');
 orders_with_a_grinder 
-----------------------
                   219
(1 row)

lantern=# SELECT count(*) AS all_orders FROM semantic.orders;
 all_orders 
------------
       7098
(1 row)
```

219 orders contained a grinder; the card shows 7,098. Nothing on the page says the slicer did not
reach it.

There are two ways to make it reach, and they are not equal:

- **Set the relationship between `order_lines` and `orders` to filter in both directions.** It works
  for this card. It also means every filter on any line-level table now spreads to orders and from
  there to every other table, and in a model with several paths between two tables, Power BI can no
  longer tell which path a filter should take. Microsoft's own guidance is to use it sparingly.
- **Write the measure to say what it means**, and leave the model alone:

```
Orders Containing Product =
    CALCULATE ( [Orders], CROSSFILTER ( order_lines[order_id], orders[order_id], BOTH ) )
```

(Not run.) `CROSSFILTER` turns on both directions for this one measure and nowhere else. The name
says what it counts, which the card that showed 7,098 did not.

The general lesson is the fan-out of lesson 3 seen from the other side. There, a join multiplied a
measure because it went from one grain to a finer one. Here, a filter fails to arrive because it
would have to travel from the finer grain to the coarser one. **Both are questions about grain, and
both are answered by deciding, in the model, which way things are allowed to flow.**
