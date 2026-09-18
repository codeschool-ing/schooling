---
title: Finding what is not there
version: 1
---

Some of the most valuable questions are about absence:

- customers who have never ordered
- products that have never sold
- orders with no payment
- users who signed up and never came back

None of these can be answered by looking at rows that exist. They are questions about **rows that do
not**, and there are three ways to ask.

## The anti-join

```sql
SELECT c.name
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE  o.id IS NULL;
```

Read it in two steps. The `LEFT JOIN` keeps every customer and fills the right-hand columns with
nulls where there was no partner. Then `WHERE o.id IS NULL` keeps exactly those — **the rows where
the join found nothing**.

This is the deliberate exception from the last section: a condition on the right-hand table in
`WHERE`, and here it is the entire point.

**The column you test must be one that cannot be null in the table.** Test `o.id` — a primary key —
and null means "no partner". Test `o.cancelled_at`, which is nullable, and you also catch orders
that exist and were never cancelled, which is a completely different question and returns a
plausible wrong answer.

## `NOT EXISTS`

```sql
SELECT c.name
FROM   customers c
WHERE  NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

Lesson 7 covers subqueries properly; this shape is worth having now because it is usually the
clearest of the three.

It says what it means — *there is no order for this customer* — with no join to reason about, no
invented nulls, and no dependence on picking a non-nullable column. `SELECT 1` is conventional:
`EXISTS` cares whether a row comes back, not what is in it.

**It also stops at the first match.** For a customer with a thousand orders, the anti-join builds
rows it will discard; `NOT EXISTS` finds one and moves on.

## `NOT IN`, which you should not use here

```sql
SELECT name FROM customers
WHERE  id NOT IN (SELECT customer_id FROM orders);
```

Reads best of the three, and **returns no rows at all**, because `orders.customer_id` is nullable
and order 1005 has a null in it. Lessons 1 and 4 both warned about this; here is where it actually
bites.

`x NOT IN (1, 2, NULL)` unfolds to `x <> 1 AND x <> 2 AND x <> NULL`, the last term is unknown, and
the whole `AND` can never be true. No error. Empty result.

It can be rescued — `WHERE customer_id IS NOT NULL` inside the subquery — and then it is a correct
query with a trap that the next person to edit it will fall into.

> **For "not in this set", write `NOT EXISTS`.** It is correct whether or not nulls are involved,
> and it does not need a reader to check.

## The three, side by side

| | correct with nulls | stops early | reads as the question |
|---|---|---|---|
| `LEFT JOIN … IS NULL` | yes, if you test a non-nullable column | no | not really |
| `NOT EXISTS` | yes, always | yes | yes |
| `NOT IN` | **no** | no | yes |

Performance between the first two is close enough that it is not the deciding factor, and lesson 10
is how you would find out for a particular query. Correctness and clarity both point at `NOT
EXISTS`, and that is enough.

## The mirror: "at least one"

The same three shapes answer the positive question, and the same one wins:

```sql
-- customers who HAVE ordered
SELECT name FROM customers c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- the same thing, badly
SELECT DISTINCT c.name FROM customers c JOIN orders o ON o.customer_id = c.id;
```

The second is lesson 4's `DISTINCT` warning and the multiplication section, arriving together: the
join builds one row per order and then throws most of them away. `EXISTS` never builds them.

**Whenever the question is "does at least one exist", the answer is `EXISTS`, not a join.** A join
is for when you want the other table's columns; `EXISTS` is for when you only want to know.
