---
title: RIGHT and FULL, briefly and with a recommendation
version: 1
---

## RIGHT JOIN

Keeps every row of the **right** table instead of the left:

```sql
SELECT c.name, o.id
FROM   customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
```

Every order appears, including 1005 with no customer, and its `c.name` is null.

**It is exactly a `LEFT JOIN` with the tables swapped**, and the swap is the recommendation:

```sql
FROM orders o LEFT JOIN customers c ON c.id = o.customer_id
```

Same rows, same answer, and it reads in the direction the query is about — *every order, with its
customer where there is one.*

> **Write `LEFT JOIN`. Swap the tables instead of reaching for `RIGHT`.**

Not because `RIGHT` is broken, but because a reader scanning a query builds a picture from the top
down, and a `RIGHT JOIN` three tables in means the thing the query is about is somewhere further
down the list rather than at the start. Mix the two in one query and almost nobody can say what the
result set is without working it out on paper.

You will still meet it — usually in a query that grew a table at a time — and recognising it is the
whole of what you need.

## FULL OUTER JOIN

Keeps everything from both sides:

```sql
SELECT c.name, o.id
FROM   customers c
FULL JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id
------------+------
 Ana Lopes  | 1001
 Ana Lopes  | 1003
 Ana Lopes  | 1004
 Bruno Sá   | 1002
 Célia Reis | NULL    <- a customer with no order
 NULL       | 1005    <- an order with no customer
```

Both kinds of orphan, in one result. It is genuinely rare in application code and genuinely useful
for one job: **reconciliation**.

```sql
SELECT coalesce(a.reference, b.reference) AS reference,
       a.amount AS ours,
       b.amount AS theirs
FROM   our_ledger   a
FULL JOIN their_statement b ON b.reference = a.reference
WHERE  a.reference IS NULL          -- only they have it
   OR  b.reference IS NULL          -- only we have it
   OR  a.amount <> b.amount;        -- both have it and they disagree
```

That is the query for *"what do these two systems disagree about"*, and it finds all three kinds of
disagreement at once. Every finance system, every import, every migration eventually needs it.

Note the `coalesce` on the first column: either side can be null, so neither alone gives you the
reference.

## Which to use, as one table

| you want | write |
|---|---|
| only rows that pair | `JOIN` |
| every row of the table the question is about | `LEFT JOIN`, with that table first |
| every row of the other one | swap the tables and use `LEFT JOIN` |
| both sets of orphans | `FULL JOIN` |
| every pair, deliberately | `CROSS JOIN` — the `the-other-joins` section |

In practice, over a career: a large majority `JOIN`, a substantial minority `LEFT JOIN`, `FULL JOIN`
a handful of times, and `RIGHT JOIN` mostly when reading somebody else's code.

## MySQL has no FULL JOIN

Worth knowing before lesson 12, because it is the one gap people hit:

```sql
SELECT … FROM a LEFT JOIN b ON …
UNION
SELECT … FROM a RIGHT JOIN b ON …;
```

A left join and a right join, unioned — `UNION` rather than `UNION ALL`, because the paired rows
appear in both halves and the duplicates have to go. It works, it is slower, and it is the standard
workaround. SQLite gained `FULL JOIN` in 2022; MariaDB still has not.
