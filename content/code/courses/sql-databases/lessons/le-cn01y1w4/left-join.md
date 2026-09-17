---
title: LEFT JOIN, and the rows that were disappearing
version: 1
---

Célia has never ordered. An inner join leaves her out, and nothing says so.

Most of the time that is wrong, because the questions people actually ask are about everybody:

- *How much has each customer spent?* — Célia has spent zero, and zero is an answer.
- *Which products have never sold?* — a question entirely about rows with no partner.
- *Show every order with its shipment* — orders not yet shipped are the ones somebody is looking
  for.

```sql
SELECT c.name, o.id, o.total
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id   | total
------------+------+-------
 Ana Lopes  | 1001 | 34.90
 Ana Lopes  | 1003 | 51.00
 Ana Lopes  | 1004 | 34.90
 Bruno Sá   | 1002 | 69.80
 Célia Reis | NULL | NULL
```

Five rows. **Every row of the left table appears at least once**; where there is no partner, the
right-hand columns are filled with `NULL`.

## What `LEFT` means, exactly

> **Keep every row of the left table. Pair it where you can. Where you cannot, invent one pair with
> nulls on the right.**

`LEFT OUTER JOIN` is the full spelling; `OUTER` is optional and almost nobody writes it.

**The sides now mean different things**, which is the difference from an inner join:

```sql
FROM customers c LEFT JOIN orders o ON …    -- every customer, orders where there are some
FROM orders o LEFT JOIN customers c ON …    -- every order, customers where there are some
```

Those are different queries. The first keeps Célia; the second keeps order 1005, the guest checkout
with no customer. Which one you want depends on the question, and getting it backwards produces a
result that looks fine and answers something else.

The habit: **put the table the question is about on the left.**

## The nulls it creates are not in the data

This catches everybody once. `o.total` is `NOT NULL` in the table — lesson 3 declared it — and here
it is, null.

The null was not read from anywhere. **The join invented it**, because there was no row to take a
value from. Which means every rule from lesson 1 applies to it:

```sql
SELECT c.name, sum(o.total) FROM customers c LEFT JOIN orders o ON … GROUP BY c.name;
```

Célia's sum is `NULL`, not `0` — because `sum` of nothing is unknown rather than zero. Almost
always what you want to show is zero:

```sql
SELECT c.name, coalesce(sum(o.total), 0) AS spent
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.name;
```

And the count needs care for the same reason:

```sql
count(*)        -- 1 for Célia: there is one row, the invented one
count(o.id)     -- 0 for Célia: the column is null and count ignores nulls
```

**`count(*)` after a `LEFT JOIN` is almost always the bug.** It counts rows, and Célia has a row.
`count(o.id)` counts orders, which is what somebody meant. This is the single most useful thing to
remember about counting after an outer join.

## Reading one

When you see a `LEFT JOIN`, three questions:

1. **Which table is the left one?** That is the set of rows the answer is about.
2. **Which columns can now be null that were not before?** Every column of the right-hand side.
3. **Does anything downstream treat those nulls correctly?** The `count(*)`, the `sum`, the `WHERE`
   — each has a rule from lesson 1 and each of them applies.

That third question is the whole of the next section, because there is one place a condition can go
that turns a `LEFT JOIN` back into an inner one without saying so.
