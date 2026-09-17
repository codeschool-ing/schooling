---
title: Counting only some of the rows, in the same pass
version: 1
---

A `WHERE` applies to the whole query. But the question is usually not *"how many paid orders"* —
it is *"how many orders, and of those how many paid, and how much did the cancelled ones come to"*,
which is three numbers about one set of rows.

You can run three queries. You can also ask each aggregate to look at a different subset, and read
the table once:

```sql
SELECT count(*)                                   AS orders,
       count(*) FILTER (WHERE status = 'paid')    AS paid,
       count(*) FILTER (WHERE status = 'cancelled') AS cancelled,
       sum(total) FILTER (WHERE status = 'paid')  AS revenue
FROM   orders
WHERE  placed_at >= DATE '2026-01-01';
```

The `WHERE` at the bottom chooses the rows the query is about. Each `FILTER` narrows further, for
one aggregate only. Four numbers, one scan, and the definitions are visible side by side instead of
scattered across three files.

`FILTER` is standard SQL. PostgreSQL has it, SQLite has it from 3.30, and **MySQL and MariaDB do
not** — which is why the next form is the one you will see most often.

## The portable form, and its trap

```sql
SELECT count(*)                                      AS orders,
       count(CASE WHEN status = 'paid' THEN 1 END)   AS paid
FROM   orders;
```

`CASE` with no `ELSE` returns `NULL` for the rows that do not match, and `count` ignores nulls. So
the non-paid rows contribute nothing. The whole mechanism is the rule from the first section, used
on purpose.

Now the trap, which is one word long:

```sql
count(CASE WHEN status = 'paid' THEN 1 ELSE 0 END)   -- counts EVERY row
```

`0` is not null. `count` counts it. This returns the total number of orders no matter what the
status is, and it is a bug that survives review because it reads like it should work — somebody
added the `ELSE 0` for tidiness and changed the answer.

`sum` is the safer habit for exactly this reason, because with `sum` the zero is correct:

```sql
sum(CASE WHEN status = 'paid' THEN 1 ELSE 0 END)     -- correct
count(CASE WHEN status = 'paid' THEN 1 END)          -- correct
count(CASE WHEN status = 'paid' THEN 1 ELSE 0 END)   -- always the row count
```

Two of those three are right. When you meet one in code, check which.

## Rates, which are an average of ones and zeroes

A proportion is a conditional sum divided by a count, and `avg` does both at once:

```sql
SELECT avg(CASE WHEN status = 'paid' THEN 1.0 ELSE 0 END) AS paid_rate
FROM   orders;
```

`0.62` — the share of orders that were paid. The `1.0` matters: with `1` and integer columns some
engines do integer division on the way and hand you a flat `0`. In PostgreSQL you can skip the
`CASE` entirely, because a boolean casts:

```sql
SELECT avg((status = 'paid')::int) AS paid_rate FROM orders;
```

And note what happens if you write `avg(CASE WHEN status = 'paid' THEN 1.0 END)` without the
`ELSE` — the non-paid rows become null, `avg` ignores them, and the answer is `1.0` for every table
that has a single paid order in it. Here the `ELSE` is required, where two snippets ago it was the
bug. That is the difference between counting rows and averaging values, and it is worth being able
to say which one you are doing.

## Turning rows into columns

The same technique with a `GROUP BY` under it is how you pivot, which is to say how you produce the
table a person actually wants to look at:

```sql
SELECT   c.region,
         count(*) FILTER (WHERE o.status = 'paid')      AS paid,
         count(*) FILTER (WHERE o.status = 'pending')   AS pending,
         count(*) FILTER (WHERE o.status = 'cancelled') AS cancelled
FROM     orders o
JOIN     customers c ON c.id = o.customer_id
GROUP BY c.region;
```

One row per region, one column per status. `GROUP BY status` would have given the same facts as
three rows per region, which is correct and harder to read across. Which shape you want depends on
who is reading, and the conditional aggregate is how you choose.

The limit is worth stating plainly: **the columns are written by hand.** A status nobody predicted
does not appear, and no error says so. If the set of values changes, group by it into rows and let
the tool at the other end lay it out — SQL returns a fixed set of columns, always, and a query
cannot discover its own shape.

## Where it replaces something worse

The shape this most often replaces is a query with several `LEFT JOIN`s onto the same table, one
per status, each with its own condition in the `ON`. That version multiplies — every one of lesson
5's problems, three times over — and it is slower, because it reads `orders` once per join. The
conditional aggregate reads it once and cannot fan out, because there is no second copy of the
table to fan out against.
