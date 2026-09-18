---
title: A join pairs rows. It does not merge tables
version: 1
---

One sentence decides whether joins ever feel simple, so it comes before any syntax.

> **A join pairs rows. Every pair that satisfies the condition becomes one row of the result.**

Not "it combines two tables into one". Not "it attaches the customer to the order". It walks the
pairs, keeps the ones the condition allows, and each survivor is a row with **all the columns of
both sides**.

Everything in this lesson follows from that, including the part that goes wrong.

## The tables for this lesson

```
customers                        orders
id  name                         id    customer_id  total
1   Ana Lopes                    1001  1             34.90
2   Bruno Sá                     1002  2             69.80
3   Célia Reis                   1003  1             51.00
                                 1004  1             34.90
                                 1005  NULL          12.00
```

Ana has three orders, Bruno has one, Célia has none, and order 1005 belongs to nobody — a guest
checkout, from lesson 1's optional relationship.

## Pairing them

```sql
SELECT c.name, o.id, o.total
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

```
 name       | id   | total
------------+------+-------
 Ana Lopes  | 1001 | 34.90
 Ana Lopes  | 1003 | 51.00
 Ana Lopes  | 1004 | 34.90
 Bruno Sá   | 1002 | 69.80
```

Four rows. Read them as pairs rather than as a table:

- `(Ana, 1001)` — the condition holds, so it is a row.
- `(Ana, 1002)` — Bruno's order, so `o.customer_id = c.id` is false. Not a row.
- `(Célia, anything)` — nothing pairs with her, so she is **absent from the result entirely**.
- `(anyone, 1005)` — its `customer_id` is null, so every comparison is unknown, and unknown is not
  true. Absent.

**`Ana Lopes` appears three times**, and that is not a defect. She is in three pairs, so there are
three rows, and each carries a full copy of her row's columns. That is the multiplication, and it
has a section of its own.

## The two facts that come out of this

**A join can produce more rows than either table has.** Three customers and five orders gave four
rows here, and with a different condition it could give fifteen. The result is not "the customers,
decorated" — it is a set of pairs, and how many there are depends on the data.

**A join can produce fewer.** Célia and order 1005 are gone. Nobody was told. If the question was
*"how many customers do we have"*, this query answers 2 and the truth is 3 — which is the failure
`left-join` exists to fix, and the reason that section matters more than it looks.

## Where the condition goes

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
```

`ON` says which pairs survive. It is almost always an equality between a foreign key and the key it
references — that is what lesson 1 built the columns for, and it is why a well-shaped schema makes
joins obvious.

It does not have to be:

```sql
ON o.customer_id = c.id AND o.total > 50      -- pairs, further restricted
ON o.created_at BETWEEN c.joined_on AND c.left_on   -- a range, not an equality
ON true                                        -- every pair, which is a CROSS JOIN
```

The difference between putting a condition in `ON` and putting it in `WHERE` is nothing at all on an
ordinary join — and is the most common bug in this course on a `LEFT JOIN`. That is the
`on-against-where` section, and it is the one to read twice.

## The mental model to carry

When you read a join, ask three questions in this order:

1. **What is one row of the result?** Not "a customer" — *a customer paired with one of their
   orders*. Saying it as a pair is what makes the rest obvious.
2. **How many times does each left-hand row appear?** Once per match. Zero if none, which is the
   inner join's silence.
3. **Which rows have no partner, and did the question want them?**

Almost every join bug is one of those three answered wrongly, and none of them is about syntax.
