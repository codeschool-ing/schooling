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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 176\" role=\"img\" aria-label=\"On the left, the five rows a LEFT JOIN produces: Ana three times, Bruno once, and Célia once with nulls in both order columns, that last row highlighted. A dashed arrow labelled WHERE o.id IS NULL crosses to the right, where a single highlighted row remains: Célia Reis. A note reads that four rows out of five are thrown away, and that is the answer.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">LEFT JOIN … ON o.customer_id = c.id</text><text x=\"14\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every customer, with nulls where there was no partner</text><rect x=\"14\" y=\"58\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1001  34.90</text><rect x=\"14\" y=\"82\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1003  51.00</text><rect x=\"14\" y=\"106\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1004  34.90</text><rect x=\"14\" y=\"130\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno Sá    1002  69.80</text><rect x=\"14\" y=\"154\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"22\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Célia Reis  NULL  NULL</text><text x=\"268\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">WHERE o.id IS NULL</text><path d=\"M258 118 L430 118\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M430 118 L422 114 L422 122 Z\" fill=\"var(--amber)\"></path><text x=\"268\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the deliberate exception: a right-hand column in WHERE</text><text x=\"444\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the rows the join found nothing for</text><rect x=\"444\" y=\"106\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"452\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Célia Reis</text><text x=\"444\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">four rows out of five are thrown away, and that is the answer.</text></svg>", "caption": "The join does the work and the WHERE is a sieve over its result. Read in that order it is two simple steps rather than one strange idiom."}
```

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
