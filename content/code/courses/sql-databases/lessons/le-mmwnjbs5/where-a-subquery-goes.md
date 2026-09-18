---
title: The three places a subquery can go
version: 1
---

A subquery is a `SELECT` written inside another statement, in brackets. There are three places one
can go, they behave differently, and knowing which you are looking at is most of reading somebody
else's query.

```sql
-- 1 · in the SELECT list, as one value
SELECT c.name, (SELECT count(*) FROM orders o WHERE o.customer_id = c.id) AS orders
FROM   customers c;

-- 2 · in FROM, as a table
SELECT t.customer_id, t.orders
FROM   (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t
WHERE  t.orders > 3;

-- 3 · in WHERE, as part of a condition
SELECT * FROM products
WHERE  category_id IN (SELECT id FROM categories WHERE archived);
```

You have already written the second of those four times in this course, in lessons 5 and 6, without
it being given a name. This is the name.

## A scalar subquery returns exactly one value

The first form is the strictest. Where a single value is expected, a subquery has to produce one
row and one column, and the database checks:

```sql
SELECT name, (SELECT price FROM products WHERE id = 7) FROM customers;
```

If that inner query matches two rows:

```
ERROR:  more than one row returned by a subquery used as an expression
```

which is a good error, because it is telling you an assumption you made silently was wrong. If it
matches **no** rows, there is no error at all — the value is `NULL`, quietly, and lesson 4's whole
section about unknowns applies to it.

That asymmetry is worth holding on to. Too many rows is loud; no rows is silent.

## A subquery in `FROM` needs a name

```sql
SELECT * FROM (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t;
```

The `t` at the end is not decoration. PostgreSQL and MySQL both refuse a derived table with no
alias, because every column of it has to be reachable as `something.column`. SQLite is relaxed
about it; write the alias anyway, so the query means the same thing everywhere.

The same rule applies to the columns inside: `count(*)` with no `AS` gives you a column whose name
is up to the database, and you cannot refer to it reliably from outside. Name everything a derived
table produces.

## A subquery in `WHERE` returns a set

```sql
WHERE category_id IN (SELECT id FROM categories WHERE archived)
```

Here one column is required and any number of rows is fine — the whole point is that there are
several. `IN`, `NOT IN`, `ANY` and `ALL` all take this shape, and `EXISTS` takes a subquery whose
columns nobody looks at. The next section is about which of them to use, and about the one that
returns nothing at all when a null gets in.

## Where a subquery may not go

Two places, and both surprise people.

**Not in `GROUP BY`**, in any engine. If you find yourself wanting to, what you want is a derived
table with the expression computed in it, and the grouping outside.

**Not usefully in `LIMIT`**, in most engines. `LIMIT (SELECT n FROM settings)` is rejected by MySQL
and accepted by PostgreSQL, which is exactly the sort of difference that makes a query
unportable for no benefit.

## They nest, and that is the problem

Nothing stops a subquery containing a subquery containing another. The syntax is fine and the
database does not mind:

```sql
SELECT * FROM (
    SELECT * FROM (
        SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id
    ) a WHERE a.n > 3
) b JOIN customers c ON c.id = b.customer_id;
```

Three levels, and to understand it you read from the inside out while the page reads from the
outside in. At four levels people stop reading and start trusting, which is where wrong queries
live.

`WITH` is the answer to that, and it is the same query with the steps named and laid flat. It gets
its own section shortly, because the readability is the feature — but first, the two forms of
subquery in `WHERE` that are not interchangeable, and the difference between them costs correctness
rather than clarity.
