---
title: Correlated subqueries, which run once per row
version: 2
---

Two subqueries that look alike and are not:

```sql
-- independent: it can be run on its own, and it is run once
WHERE price > (SELECT avg(price) FROM products)

-- correlated: it mentions the outer query, and it cannot be run on its own
WHERE price > (SELECT avg(price) FROM products p2 WHERE p2.category_id = p.category_id)
```

The second names `p`, which belongs to the query around it. Paste it into a client on its own and
it is a syntax error. That single reference is what makes it correlated, and it changes when the
subquery runs: conceptually, **once for every row of the outer query**.

*"More expensive than the average for its own category"* is a real question that has no other short
spelling, so the form earns its place. The cost is worth being honest about.

## The mental model and what actually happens

Think of it as a loop: for each product, work out that category's average, compare. A thousand
products, a thousand little queries.

The database usually does not do that. A planner that recognises the shape rewrites it into an
aggregate computed once per category and joined — the same answer for a fraction of the work. But
"usually" is doing real work in that sentence. Whether the rewrite happens depends on the engine,
the version, and what else is in the query, which is why a correlated subquery is the classic
"fast in development, slow in production" defect: a hundred rows hides it and a million does not.

The shape to be suspicious of is one where the subquery cannot be pulled out — something it
computes depends on the outer row in a way no join expresses. Then the loop is real.

## Where it earns its place

**`EXISTS` and `NOT EXISTS`**, which are correlated by definition and which the previous section
recommends. Planners handle these particularly well: a semi-join or an anti-join stops at the first
match instead of counting.

**A single scalar column**, when one is genuinely all you need:

```sql
SELECT c.name,
       (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id) AS last_order
FROM   customers c;
```

Readable, and a customer with no orders gets `NULL` rather than disappearing — which is the same
outcome as a `LEFT JOIN` and takes less writing.

## Where it stops earning it

Add two more columns and the shape turns on you:

```sql
SELECT c.name,
       (SELECT count(*)         FROM orders o WHERE o.customer_id = c.id) AS orders,
       (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id) AS last_order,
       (SELECT sum(o.total)     FROM orders o WHERE o.customer_id = c.id) AS spent
FROM   customers c;
```

Three subqueries over the same table, asking about the same rows, three times. One `LEFT JOIN` with
a `GROUP BY` does the lot in one pass:

```sql
SELECT   c.name, count(o.id) AS orders, max(o.ordered_on) AS last_order,
         coalesce(sum(o.total), 0) AS spent
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

Note `count(o.id)` rather than `count(*)`, for lesson 6's reason. The rewrite is a good habit for a
simple test: **when two correlated subqueries name the same table, they want to be one join.**

## The same bug one layer up

An application that loops over customers and runs a query per customer is doing by hand what a
correlated subquery does inside the database — and doing it far worse, because every iteration is a
round trip across a network. That is the N+1 problem, it is lesson 11's subject, and it is worth
recognising that the two are the same mistake at different altitudes. At least the database has a
planner that might rescue it.

## Correlated `UPDATE`, and the trap in it

Backfilling a denormalised column is where most people meet this form for real:

```sql
UPDATE customers c
SET    order_count = (SELECT count(*) FROM orders o WHERE o.customer_id = c.id);
```

That is correct and it updates every customer, including the ones with no orders — where `count(*)`
over no rows is `0`, which is what you want. Change the aggregate and it stops being what you want:

```sql
UPDATE customers c
SET    last_order_at = (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id);
```

A customer with no orders is now set to `NULL`, which may be right, and a customer whose orders
were archived last night is **also** set to null, overwriting a value that was true. If you meant
to touch only the rows that have a match, say so:

```sql
UPDATE customers c
SET    last_order_at = (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id)
WHERE  EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

Two correlated subqueries, one in the `SET` and one in the `WHERE`, which is ordinary in this shape.

And run it inside a transaction, so that a mistake is one `ROLLBACK` rather than a restore. That is
lesson 8, and it is the next lesson for a reason: from here on, the statements you write change
things.
