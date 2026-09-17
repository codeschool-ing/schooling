---
title: Counting correctly, which is where joins and aggregates collide
version: 1
---

Lesson 5 said a join pairs rows and that the pairing multiplies. Now you have functions that add
those rows up, and the two facts meet. This section is the most practically valuable one in the
lesson, because every bug in it produces a plausible number rather than an error.

## The one everybody writes

*"How many orders has each customer placed?"* Customers with none must appear with a zero, so it is
a `LEFT JOIN`:

```sql
SELECT   c.name, count(*) AS orders
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

Celia has never ordered. Her row says **1**.

Nothing went wrong in the join: a `LEFT JOIN` keeps the unmatched left row and fills the right-hand
columns with nulls, so Celia is in the result exactly once, in a row where every `o.` column is
null. `count(*)` counts rows. There is one row. It says one.

```sql
SELECT   c.name, count(o.id) AS orders
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

Celia says **0**, because `count(o.id)` skips the nulls — the rule from the first section of this
lesson, doing something useful for once.

> **After a `LEFT JOIN`, count a column from the right-hand table, never `count(*)`.**

And the column you count must be one that cannot be null in a real matched row: the primary key is
always safe, a nullable column is not. `count(o.shipped_at)` would count shipped orders, which may
well be a different number and no error will tell you.

Sums have the same shape and a different symptom. `sum(o.total)` for Celia is null, not zero,
because summing no values has no answer — so wrap it:

```sql
SELECT   c.name, count(o.id) AS orders, coalesce(sum(o.total), 0) AS spent
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

## The multiplication, now that it is being summed

Lesson 5's worst case was two one-to-many joins from the same table. Here is what aggregates do
with it:

```sql
SELECT   o.id, sum(l.quantity) AS items, sum(p.amount) AS paid
FROM     orders o
JOIN     order_lines l ON l.order_id = o.id
JOIN     payments    p ON p.order_id = o.id
GROUP BY o.id;
```

Three lines and two payments make six rows. Every quantity is added twice and every payment three
times. Both columns are wrong, both are the right order of magnitude, and the query reads
perfectly.

`count(DISTINCT …)` rescues the counts:

```sql
count(DISTINCT l.id)   -- 3, correct
count(DISTINCT p.id)   -- 2, correct
```

**It does not rescue the sums.** There is no `sum(DISTINCT l.quantity)` that means anything:
distinct *values* is not distinct *rows*, so two lines of quantity 2 would collapse into one and
the total would drop to 2. Occasionally somebody writes it and the number gets quietly smaller.

The fix is the one lesson 5 gave, and it is worth repeating because it is the general answer:
**aggregate each side separately, then join the summaries.**

```sql
SELECT o.id, coalesce(l.items, 0) AS items, coalesce(p.paid, 0) AS paid
FROM   orders o
LEFT JOIN (SELECT order_id, sum(quantity) AS items FROM order_lines GROUP BY order_id) l
       ON l.order_id = o.id
LEFT JOIN (SELECT order_id, sum(amount)   AS paid  FROM payments    GROUP BY order_id) p
       ON p.order_id = o.id;
```

Each subquery is one row per order, so neither can multiply the other. Lesson 7 gives this shape a
name and a tidier syntax; the arithmetic is what matters and it does not change.

## `count(DISTINCT)` is not free

It has to remember every value it has seen, where `count(*)` only has to remember a number. On a
large table that is the difference between a scan and a scan plus a sort or a hash table, and it is
a common reason for a query that used to be quick. When it appears only to undo a fan-out you
created, the separate-aggregates shape above is both faster and more honest.

## The check that catches all of it

Before you believe an aggregate over a join, ask what one row of the **ungrouped** query is. Say it
as a sentence: *"one row per order per line per payment."* If that sentence contains the word "per"
more than once, every `sum` in the query is counting something more than once.

And then verify it, which costs one query:

```sql
SELECT count(*) FROM orders;                                   -- 1 000
SELECT count(*) FROM orders o JOIN order_lines l ON …;          -- 3 200
```

If the second is bigger and you did not expect it to be, you have found the multiplication before
it reached a report rather than after.
