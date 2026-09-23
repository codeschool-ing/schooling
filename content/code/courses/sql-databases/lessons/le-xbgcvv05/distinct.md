---
title: DISTINCT, which is usually a symptom
version: 2
---

```sql
SELECT DISTINCT category FROM products;
```

`DISTINCT` removes duplicate rows from the result. It applies to **the whole output row**, not to
one column, which is the first thing people get wrong:

```sql
SELECT DISTINCT category, name FROM products;
```

That is distinct *pairs*. Since `name` is nearly unique, almost nothing is removed and the query
looks as though `DISTINCT` did not work. It did; you asked a different question.

## It is not free

Removing duplicates means the database has to compare rows with each other, which it does by
sorting or by hashing. On a large result that is real work and real memory, and it happens after
everything else in the query.

That alone is not an argument against it. The argument is the next section.

## The useful suspicion

> **When `DISTINCT` was added to make a wrong answer look right, it hid a defect instead of fixing
> one.**

This is the pattern, and it is one of the most common mistakes in SQL. Lesson 5 is about joins, and
this is the trap it lands in:

```sql
SELECT DISTINCT c.name
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

Somebody wanted "customers who have ordered". The join produces one row per **order**, so a
customer with five orders appears five times, and `DISTINCT` collapses them. The answer is now
correct and the query is doing far more work than it needs — and the moment somebody adds a column,
or a `count(*)`, the duplication comes back in a form `DISTINCT` no longer hides.

What was actually meant:

```sql
SELECT c.name
FROM   customers c
WHERE  EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

`EXISTS` asks whether there is at least one, and stops looking. No duplication is created, so none
has to be removed, and the database can stop at the first match per customer instead of fetching
every order.

So the habit worth building:

> **When you reach for `DISTINCT`, ask where the duplicates came from.** If the answer is "the join
> multiplied the rows", the join is the thing to change.

Legitimate uses remain, and they have a different shape: you want the set of values a column takes,
and the duplicates are in the data rather than created by the query.

```sql
SELECT DISTINCT category FROM products ORDER BY category;
```

## `DISTINCT ON`, which is PostgreSQL's and is excellent

```sql
SELECT DISTINCT ON (customer_id) customer_id, id, ordered_on, total
FROM   orders
ORDER BY customer_id, ordered_on DESC;
```

**One row per customer — the most recent order of each.** That is a question people write
complicated subqueries for, and here it is four words.

The rule is exact and worth stating because it is the part people get wrong: `DISTINCT ON (x)`
keeps the **first** row of each group of `x`, and *first* means first in the `ORDER BY`. So the
`ORDER BY` must begin with the same expressions as the `DISTINCT ON`, and what comes after decides
which row survives.

Change `DESC` to `ASC` and you get each customer's first order instead. Leave the second key out
and you get an arbitrary one of theirs, which is a bug that looks like a working query.

It is not standard SQL. Lesson 6's window functions do the same job portably and more verbosely,
and lesson 12 is where the difference matters.

## `UNION` removes duplicates too

Worth knowing now because it is the same cost in a place people do not expect it:

```sql
SELECT name FROM products UNION     SELECT name FROM archived_products;   -- removes duplicates
SELECT name FROM products UNION ALL SELECT name FROM archived_products;   -- keeps them
```

**`UNION` deduplicates and `UNION ALL` does not**, which means the plain spelling is the expensive
one. When you know the two sides cannot overlap — or when duplicates are fine — `UNION ALL` is both
faster and more honest about what you asked for.
