---
title: Derived tables, and the three shapes you have already written
version: 1
---

A subquery in `FROM` is a **derived table**: a table that exists for the length of one statement and
has no name on disk. Everything that works on a real table works on it — you can join it, group it,
join two of them together.

Three shapes from earlier lessons are all this, which is worth collecting in one place because you
will write them for the rest of your working life.

## One · filtering on something you computed

Lesson 6 could not write `HAVING orders > 3` portably, because PostgreSQL does not accept an output
name there. Compute it inside, filter outside, and the problem disappears:

```sql
SELECT *
FROM  (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t
WHERE t.orders > 3;
```

Once the aggregate is a column of a table, the filter is an ordinary `WHERE`. This is also the only
way to filter on a **window** function, for the running-order reason lesson 6 gave:

```sql
SELECT * FROM (
    SELECT o.*, row_number() OVER (PARTITION BY customer_id ORDER BY placed_at DESC) AS n
    FROM   orders o
) t
WHERE t.n <= 3;
```

## Two · aggregating each side before joining

Lessons 5 and 6 both arrived at this, from different directions, and it is the general cure for the
join multiplication:

```sql
SELECT o.id, coalesce(l.items, 0) AS items, coalesce(p.paid, 0) AS paid
FROM   orders o
LEFT JOIN (SELECT order_id, sum(quantity) AS items FROM order_lines GROUP BY order_id) l
       ON l.order_id = o.id
LEFT JOIN (SELECT order_id, sum(amount)   AS paid  FROM payments    GROUP BY order_id) p
       ON p.order_id = o.id;
```

Each derived table is one row per order. Two things that are each one-per-order cannot multiply
each other, and that is the whole argument.

## Three · giving a messy expression a name

```sql
SELECT bucket, count(*)
FROM  (SELECT CASE WHEN total < 50 THEN 'small'
                   WHEN total < 200 THEN 'medium'
                   ELSE 'large' END AS bucket
       FROM orders) t
GROUP BY bucket;
```

`GROUP BY` cannot contain a subquery and repeating a `CASE` in two clauses is how they drift apart.
Compute it once, group outside.

## A derived table cannot see the query around it

This is the difference from the last section, and it is absolute:

```sql
SELECT c.name, t.last
FROM   customers c
JOIN  (SELECT max(placed_at) AS last FROM orders WHERE customer_id = c.id) t ON true;
```

```
ERROR:  invalid reference to FROM-clause entry for table "c"
```

The derived table is evaluated before the join, so `c` does not exist yet. A correlated subquery in
the `SELECT` list may refer outward; one in `FROM` may not.

Unless you say `LATERAL`, which lesson 5 mentioned and left to this lesson:

```sql
SELECT c.name, t.*
FROM   customers c
CROSS JOIN LATERAL (
    SELECT o.id, o.placed_at FROM orders o
    WHERE  o.customer_id = c.id
    ORDER BY o.placed_at DESC
    LIMIT  3
) t;
```

`LATERAL` says: run this once per row of what came before, with that row's values available. It is
the one way to write "the top three per group" with a `LIMIT` rather than a window function, and it
is the right tool when the inner query is expensive and the limit saves real work. PostgreSQL and
MySQL 8 have it; SQLite does not. Use `CROSS JOIN LATERAL` when every outer row must have a match
and `LEFT JOIN LATERAL … ON true` when it need not.

## Where the filter ends up

A useful thing to know, and one you can check rather than believe:

```sql
SELECT * FROM (SELECT * FROM orders) t WHERE t.customer_id = 7;
```

The planner pushes that condition **inside**, so the derived table never builds a thousand rows to
throw away 999. That is standard behaviour and it is why a derived table normally costs nothing.

It does not always happen. A filter cannot be pushed through a window function, or a `DISTINCT`, or
a `LIMIT`, because doing so would change the answer — a `row_number()` computed over fewer rows is
a different `row_number()`. So this:

```sql
SELECT * FROM (
    SELECT o.*, row_number() OVER (ORDER BY placed_at) AS n FROM orders o
) t
WHERE t.customer_id = 7;
```

numbers every order in the table and then keeps one customer's. If you wanted the numbering to be
per customer, the `WHERE` belongs inside, or the `PARTITION BY` belongs in the window — and those
are two different questions with two different answers.

**When a derived table is slower than you expected, this is the first thing to check**, and lesson
10 shows you how to see it rather than guess.

## Name everything

```sql
FROM (SELECT customer_id, count(*) FROM orders GROUP BY customer_id) t
```

`t.count`? `t.?column?`? It depends on the engine, and an unnamed column in a derived table is a
query that breaks when somebody upgrades. Write `count(*) AS orders`, and give the derived table an
alias even where SQLite would let you skip it.

And when you find yourself nesting these three deep, stop and read the next section. It is the same
query with the steps named.
