---
title: INNER JOIN, the one you write most
version: 1
---

```sql
SELECT c.name, o.id, o.total
FROM   customers c
INNER JOIN orders o ON o.customer_id = c.id;
```

`INNER` is the default, so almost nobody writes it:

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
```

**Only pairs that satisfy the condition survive.** A row on either side with no partner is not in
the result, and nothing says so.

## The aliases are not decoration

```sql
SELECT c.name, o.id
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

Both tables have `id`. Writing `SELECT id` is an error — *column reference "id" is ambiguous* — and
that error is the good case. The bad case is two tables where only one has the column today, so the
unqualified name works, and somebody adds that column to the other table next year. The query is
still valid and now reads the wrong one.

> **Qualify every column in a join. Even the unambiguous ones.**

And the aliases make it readable: `c` and `o` in a two-table query, meaningful short names in a
five-table one. `customers AS c` is the standard spelling and `customers c` is the same thing.

## The old syntax, and why it is worth recognising

You will meet this in existing code:

```sql
SELECT c.name, o.id
FROM   customers c, orders o
WHERE  o.customer_id = c.id;
```

A comma between tables means every pair, and the `WHERE` then throws most of them away. It produces
the same answer as the explicit join above and it is worse in two ways:

- **The join condition and the filters are mixed together.** Reading a five-table query in this
  style, you cannot tell at a glance which conditions connect the tables and which select rows.
- **Forgetting one is not an error.** Leave out `WHERE o.customer_id = c.id` and you get every
  customer paired with every order — three times five rows here, and three million times five
  million on a real system. The query runs, returns nonsense, and takes the database with it.

Explicit `JOIN … ON` cannot be forgotten in the same way: the `ON` is part of the syntax. Use it.

## An inner join is symmetric

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
FROM orders o JOIN customers c ON c.id = o.customer_id
```

Same rows, same answer. Nothing about `INNER JOIN` prefers one side, so which table you put first is
a readability decision — start with the thing the query is *about*, and join what decorates it.

**This stops being true for `LEFT JOIN`**, where the sides mean different things. That is the next
section but one, and it is the reason people who learned joins as "combining tables" get stuck.

## The condition can be anything, and usually is not

Almost every join you write will be an equality on a foreign key:

```sql
ON o.customer_id = c.id
```

That is not a rule of SQL; it is what a normalised schema makes natural, and it is worth noticing
that lessons 1 and 2 were building towards exactly this. A table with a list in a cell, or a
repeated name instead of a reference, cannot be joined on — which is the practical cost of the
shapes those lessons refused.

When the condition is something else, it is worth a comment:

```sql
-- a price valid at the time of the order, not the current one
JOIN price_history p
  ON p.product_id = l.product_id
 AND o.ordered_on BETWEEN p.valid_from AND p.valid_to
```

That is a range join, it is a real pattern, and it is also where the multiplication in the next
section bites hardest — if two rows of `price_history` overlap, every order in the overlap is
counted twice, and nothing refuses it.
