---
title: The other joins, and one to avoid
version: 2
---

## CROSS JOIN

Every row of one table paired with every row of the other, with no condition at all:

```sql
SELECT c.name, s.size FROM colours c CROSS JOIN sizes s;
```

Four colours and three sizes gives twelve rows. It is the only join whose row count you can predict
exactly, and it is right when you genuinely want every combination:

- **every variant of a product** — colour by size — to seed a table;
- **every day in a range against every shop**, so a report has a zero for the days nothing was sold
  rather than a gap;
- **a small lookup joined to everything**, such as one row of settings.

That second one is worth knowing, because "the report is missing the days with no sales" is a
question people answer by editing the spreadsheet afterwards:

```sql
SELECT d.day, s.name, coalesce(sum(o.total), 0) AS sales
FROM   generate_series('2026-03-01'::date, '2026-03-31', '1 day') AS d(day)
CROSS JOIN shops s
LEFT JOIN orders o ON o.shop_id = s.id AND o.ordered_on = d.day
GROUP BY d.day, s.name;
```

A row for every shop on every day, whether or not anything happened. That is a `CROSS JOIN` doing
the job nothing else can.

**And an accidental one is a catastrophe.** The comma syntax from the `inner-join` section produces
a cross join when the `WHERE` is forgotten — a million rows against a million rows is a trillion,
and the database will try. A `CROSS JOIN` written on purpose is safe because somebody typed the
words.

## USING

Shorthand for an equality on a column of the same name in both tables:

```sql
FROM orders o JOIN customers c USING (customer_id)    -- if both call it that
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
```

It is shorter, and it does one thing worth knowing: **the joined column appears once in the result**
rather than twice, and it may be referred to unqualified.

It only works where both sides use the same name, which a schema following lesson 3's convention
usually does not — `customers.id` against `orders.customer_id`. Where it fits, it is fine.

## NATURAL JOIN, which you should never write

```sql
FROM orders NATURAL JOIN customers
```

It joins on **every column the two tables happen to share a name for**, with no condition written
anywhere.

That sounds convenient and it is a trap with a delay on it. Today the shared column is
`customer_id` and the query is right. Then somebody adds `created_at` to both tables — a perfectly
ordinary thing to do, in an unrelated migration — and the join silently becomes *"the same customer
**and** created at the same instant"*.

The result is almost always empty. Nothing changed in the query. Nothing errored. The migration
that broke it did not mention it.

> **The join condition should be visible in the query that depends on it.** `NATURAL JOIN` makes it
> depend on the schema's naming, which is not under that query's control and changes without
> reference to it.

Recognise it in somebody else's code, and replace it with the `ON` it meant.

## LATERAL

A join whose right-hand side may refer to the left. It is properly lesson 7's, and it belongs in
this list because it solves a question joins otherwise cannot:

```sql
SELECT c.name, o.id, o.total
FROM   customers c
LEFT JOIN LATERAL (
    SELECT id, total FROM orders o
    WHERE  o.customer_id = c.id
    ORDER BY o.ordered_on DESC
    LIMIT  3
) o ON true;
```

**The three most recent orders of each customer.** An ordinary join cannot do that — it has no way
to say "per row of the left table" — and without `LATERAL` this needs a window function and a
filter.

`ON true` is idiomatic: the pairing is already decided inside the subquery, so the join condition
has nothing left to say.

## The whole set

| | keeps | when |
|---|---|---|
| `JOIN` | pairs only | most of the time |
| `LEFT JOIN` | every left row | the question includes rows with nothing |
| `RIGHT JOIN` | every right row | swap the tables and use `LEFT` instead |
| `FULL JOIN` | everything | reconciling two sources |
| `CROSS JOIN` | every combination | generating a grid on purpose |
| `LATERAL` | per-row subquery | top N per group, and anything else that needs the left row |
| `NATURAL JOIN` | — | never |
