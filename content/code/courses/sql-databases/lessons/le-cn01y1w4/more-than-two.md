---
title: More than two tables, and a table joined to itself
version: 2
---

Joins chain. Each one pairs what you have so far with one more table.

```sql
SELECT c.name, o.id, p.name AS product, l.quantity
FROM   customers   c
JOIN   orders      o ON o.customer_id = c.id
JOIN   order_lines l ON l.order_id    = o.id
JOIN   products    p ON p.id          = l.product_id
WHERE  o.ordered_on >= '2026-03-01';
```

Four tables, three joins, and **one row per order line** — which is the question to keep asking as
the chain grows. A customer with two orders of three lines each produces six rows, and their name
is in all six.

## Writing one that works first time

**Start with the table the question is about, and add one join at a time**, checking the count after
each. Lesson 4's technique, applied here:

```sql
SELECT count(*) FROM orders o;                              -- 5
SELECT count(*) FROM orders o JOIN customers c ON …;        -- 4, and that is order 1005 leaving
SELECT count(*) FROM orders o JOIN customers c ON … JOIN order_lines l ON …;   -- 11
```

The number moving from 4 to 11 tells you the grain changed: you are no longer counting orders. If
that was not intended, you found it on the join that caused it rather than in a report three weeks
later.

**And a count that drops when you add a join is the interesting one.** It means rows had no partner,
which is either a data problem or a `LEFT JOIN` you have not written yet.

## Order does not change the answer

```sql
FROM a JOIN b ON … JOIN c ON …
FROM c JOIN b ON … JOIN a ON …
```

Same rows, for inner joins. The planner decides the actual order of work by its own estimates, and
lesson 10 is where you see what it chose.

**With outer joins the order does matter**, because a `LEFT JOIN` is not symmetric. This is the
case to be careful of:

```sql
FROM customers c
LEFT JOIN orders o      ON o.customer_id = c.id
JOIN      order_lines l ON l.order_id    = o.id;
```

The inner join at the end **undoes the left join**, for the same reason a `WHERE` does: Célia's
invented row has a null `o.id`, nothing in `order_lines` pairs with it, and she is discarded.

Once a chain goes outer, the joins after it usually have to be outer too:

```sql
LEFT JOIN orders      o ON o.customer_id = c.id
LEFT JOIN order_lines l ON l.order_id    = o.id
```

## Joining a table to itself

A table can appear twice, and the aliases stop being a convenience and become necessary.

**A hierarchy.** Employees with their managers, where both are employees:

```sql
SELECT e.name AS employee, m.name AS manager
FROM   employees e
LEFT JOIN employees m ON m.id = e.manager_id;
```

`LEFT`, because somebody at the top has no manager, and an inner join would quietly drop the chief
executive.

**Comparing rows to each other.** Pairs of products at the same price:

```sql
SELECT a.name, b.name, a.price
FROM   products a
JOIN   products b ON b.price = a.price AND b.id > a.id;
```

The `b.id > a.id` is doing two jobs, and both matter: without it, every product pairs with itself,
and every genuine pair appears twice in both orders. A strict inequality on the key gives each pair
exactly once.

**The previous row.** Which is a real question — the gap between a customer's orders — and is
painful with a self-join and trivial with lesson 6's window functions:

```sql
-- the self-join version, which needs a correlated subquery to find "the previous one"
SELECT o.id, o.ordered_on,
       (SELECT max(p.ordered_on) FROM orders p
        WHERE p.customer_id = o.customer_id AND p.ordered_on < o.ordered_on) AS previous
FROM   orders o;

-- lesson 6
SELECT id, ordered_on,
       lag(ordered_on) OVER (PARTITION BY customer_id ORDER BY ordered_on) AS previous
FROM   orders;
```

Both are correct. The second says what it means, and it is the reason window functions exist.

## Reading a five-table query

Somebody else's, at speed:

1. **Find the first table in `FROM`.** That is what the query is about — or should be.
2. **Read each `ON` as a sentence.** `l.order_id = o.id` is *"the line belongs to the order"*. Any
   `ON` you cannot read that way deserves a second look; it is either a range join or a mistake.
3. **Note every `LEFT`**, and check nothing after it is inner.
4. **Say what one row is.** *"One row per order line."* If you cannot, the query does not know
   either.
5. **Then read `WHERE`**, looking for a right-hand column, which is the previous section's bug.

That is five questions and none of them is about syntax, which is the point: joins are hard because
of what they mean, not because of how they are written.
