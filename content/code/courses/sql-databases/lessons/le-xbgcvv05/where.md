---
title: WHERE, and the rule for keeping a row
version: 2
---

`WHERE` keeps a row when the condition is **true**. Not "not false" — true. That distinction is
lesson 1's three-valued logic arriving in a query, and it has its own section two along.

```sql
SELECT name, price
FROM   products
WHERE  price > 20;
```

## The comparisons

```sql
WHERE price = 20
WHERE price <> 20          -- != also works and <> is the standard
WHERE price > 20
WHERE price BETWEEN 20 AND 50      -- inclusive at both ends
WHERE category IN ('kitchen', 'garden')
WHERE created_at >= date '2026-01-01'
```

**`BETWEEN` is inclusive of both bounds**, which is fine for integers and a trap for timestamps:

```sql
WHERE created_at BETWEEN '2026-03-01' AND '2026-03-31'
```

That misses almost the whole of the 31st. A bare date is midnight, so the upper bound is
`2026-03-31 00:00:00` and everything later that day is outside it. The shape that is always right:

```sql
WHERE created_at >= '2026-03-01' AND created_at < '2026-04-01'
```

Greater-or-equal at the start, **strictly less** at the start of the next period. It reads slightly
worse and it is correct for dates, timestamps, months and years without thinking about how many
days February has.

## Combining, and the precedence that bites

`AND` binds tighter than `OR`. Which means these two are different queries:

```sql
WHERE category = 'kitchen' OR category = 'garden' AND price < 50
WHERE (category = 'kitchen' OR category = 'garden') AND price < 50
```

The first is *kitchen at any price, or garden under 50* — almost certainly not what somebody
writing it meant. The second is the intended one.

> **Parenthesise whenever `AND` and `OR` appear together.** Even when you are sure. The reader is
> not sure, and the reader is you in six months.

`NOT` negates, and combined with nulls it does something you would not predict — the
`null-in-a-query` section.

## `WHERE` runs before `SELECT`

From the first section, and it is the most common beginner error, so it is worth seeing again with
the fix:

```sql
SELECT price * 1.23 AS gross FROM products WHERE gross > 100;    -- error
SELECT price * 1.23 AS gross FROM products WHERE price * 1.23 > 100;   -- works
```

If repeating the expression is ugly — and on a long one it is — lesson 7's common table expressions
are the clean answer:

```sql
WITH priced AS (
    SELECT name, price * 1.23 AS gross FROM products
)
SELECT * FROM priced WHERE gross > 100;
```

## Functions on a column have a cost you cannot see yet

These two find the same rows:

```sql
WHERE extract(year FROM created_at) = 2026
WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'
```

The second can use an index on `created_at`. **The first cannot**, because the database would have
to compute the function for every row before it could compare anything, and an index on the column
says nothing about the function's result.

The rule, and it is one of the few things worth carrying from this lesson into lesson 9:

> **Leave the column bare on one side of the comparison. Do the arithmetic on the other side.**

`WHERE price * 1.23 > 100` has the same problem, and `WHERE price > 100 / 1.23` does not. It is
not a difference you can see on a small table, and it is the difference between milliseconds and
minutes on a large one.

## The two clauses that are not filters

Worth naming now so they are not confused later:

```sql
WHERE  price > 20        -- discards ROWS, before grouping
HAVING count(*) > 3      -- discards GROUPS, after grouping
```

They are not alternatives, they run at different moments, and putting an aggregate in `WHERE` is an
error rather than a slow version of the right thing. Lesson 6.
