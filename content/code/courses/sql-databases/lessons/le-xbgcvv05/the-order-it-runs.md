---
title: The order you write it, and the order it runs
version: 1
---

One idea first, because it explains most of the confusing errors you will meet in the next year.

**You write the clauses in one order. The database runs them in another.**

```sql
SELECT   name, price                  -- 5. and finally, pick the columns
FROM     products                     -- 1. first, which rows exist
WHERE    price > 20                   -- 2. throw away the ones that fail
GROUP BY category                     -- 3. lesson 6
HAVING   count(*) > 1                 -- 4. lesson 6
ORDER BY price DESC                   -- 6. arrange what survived
LIMIT    10;                          -- 7. take the first few
```

The numbers are the order it actually happens. `FROM` is first because nothing can be filtered
before it is known what there is. `SELECT` — the clause you wrote first — happens near the **end**.

## What that explains

Give a column a new name and try to use it:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  gross > 100;
```

```
ERROR:  column "gross" does not exist
LINE 3: WHERE  gross > 100;
               ^
```

`gross` is invented by `SELECT`, and `WHERE` ran before `SELECT`. When the filter was being
evaluated the name did not exist. The error is accurate and says nothing about why.

Repeat the expression instead:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  price * 1.23 > 100;
```

## And what is different about ORDER BY

```sql
SELECT price * 1.23 AS gross
FROM   products
ORDER BY gross DESC;
```

That works. `ORDER BY` runs **after** `SELECT`, so by the time it looks for `gross`, the name
exists.

So the rule is not "aliases never work". It is exactly:

> **An alias from `SELECT` is usable in `ORDER BY`, and not in `WHERE`, `GROUP BY` or `HAVING`.**

Which is not a quirk to memorise once you can see the order. It is the order.

## The whole sequence, once

| | clause | what it does |
|---|---|---|
| 1 | `FROM` / `JOIN` | assemble the rows to consider |
| 2 | `WHERE` | discard rows that fail a test |
| 3 | `GROUP BY` | collapse the survivors into groups |
| 4 | `HAVING` | discard whole groups |
| 5 | `SELECT` | compute the output columns, and name them |
| 6 | `ORDER BY` | arrange the result |
| 7 | `LIMIT` / `OFFSET` | take a slice of it |

Two more consequences worth having now, both of which come up in later lessons:

**`WHERE` filters rows, `HAVING` filters groups.** They are not alternatives; they run at different
moments on different things. Lesson 6.

**`LIMIT` is last**, so it takes a slice of an already-sorted result. It does not make the database
stop early in any way you can reason about — and with no `ORDER BY` it takes an arbitrary slice of
an arbitrary arrangement, which is the `limit-and-paging` section.

## It is a model, not a promise about the machine

A caution that matters from lesson 10 onwards.

The list above is the **logical** order — what the answer is defined to be. The database is free to
do the work in any order that produces the same answer, and it will: it might use an index to avoid
sorting, filter while it reads rather than afterwards, or stop reading once `LIMIT` is satisfied.

That freedom is the whole subject of the execution plan. What it never does is change the answer.
So use this order to reason about **what a query means**, and the plan in lesson 10 to reason about
**what it costs.** Confusing the two is how people end up believing that rearranging the clauses
makes a query faster, which it does not, because you did not change what you asked for.
