---
title: HAVING filters groups, WHERE filters rows
version: 1
---

Two lessons promised this section, so here is the sentence they were promising:

> **`WHERE` runs before the grouping and decides which rows go in. `HAVING` runs after it and
> decides which groups come out.**

Everything else about `HAVING` follows from that, including why it exists at all — by the time you
have a count, the rows it counted are gone, and `WHERE` has long since finished.

Lesson 4's running order, extended with the two clauses this lesson adds:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"Seven stages in a row, left to right, with arrows between them: FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY and LIMIT. WHERE and HAVING are drawn highlighted as the two sieves, WHERE labelled throws rows away and HAVING labelled throws piles away. A dashed vertical line falls just after GROUP BY, with no aggregate exists yet written to its left and aggregates exist to its right.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The order the database runs the clauses in, which is not the order they are written.</text><rect x=\"14\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"56.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">FROM</text><path d=\"M100 71 L108 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M108 71 L102 68 L102 74 Z\" fill=\"var(--wire)\"></path><rect x=\"110\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"152.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">WHERE</text><path d=\"M196 71 L204 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 71 L198 68 L198 74 Z\" fill=\"var(--wire)\"></path><rect x=\"206\" y=\"56\" width=\"96\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"254.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">GROUP BY</text><path d=\"M304 71 L312 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M312 71 L306 68 L306 74 Z\" fill=\"var(--wire)\"></path><rect x=\"314\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"356.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">HAVING</text><path d=\"M400 71 L408 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M408 71 L402 68 L402 74 Z\" fill=\"var(--wire)\"></path><rect x=\"410\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"452.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SELECT</text><path d=\"M496 71 L504 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M504 71 L498 68 L498 74 Z\" fill=\"var(--wire)\"></path><rect x=\"506\" y=\"56\" width=\"96\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"554.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">ORDER BY</text><path d=\"M604 71 L612 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M612 71 L606 68 L606 74 Z\" fill=\"var(--wire)\"></path><rect x=\"614\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"656.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">LIMIT</text><path d=\"M308.0 44 L308.0 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" fill=\"none\"></path><text x=\"300.0\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">no aggregate exists yet</text><text x=\"316.0\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">aggregates exist</text><path d=\"M152.0 88 L152.0 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"152.0\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">throws rows away</text><path d=\"M356.0 88 L356.0 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"356.0\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">throws piles away</text><text x=\"14\" y=\"148\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">An aggregate in WHERE is not a rule to remember: by then nothing has been counted.</text></svg>", "caption": "The dashed line is the whole section. WHERE sits on the left of it and HAVING on the right, and every rule about which one takes an aggregate follows from where they stand."}
```

Read that list and the error you are about to meet stops being mysterious:

```sql
SELECT customer_id FROM orders WHERE count(*) > 3 GROUP BY customer_id;
```

```
ERROR:  aggregate functions are not allowed in WHERE
```

When `WHERE` runs, there are no groups and there is no count — there is a row, on its own, and
`count(*)` of one row is not a question. Move it:

```sql
SELECT   customer_id, count(*)
FROM     orders
GROUP BY customer_id
HAVING   count(*) > 3;
```

## The query that needs both, which is most of them

*"Customers with more than three orders in 2026."* Two conditions, and they go in different
clauses, because one is about a row and the other is about a pile:

```sql
SELECT   customer_id, count(*) AS orders_2026
FROM     orders
WHERE    ordered_on >= DATE '2026-01-01'
  AND    ordered_on <  DATE '2027-01-01'
GROUP BY customer_id
HAVING   count(*) > 3;
```

The year is a property of an order, so it is a `WHERE`. The count is a property of the customer's
pile, so it is a `HAVING`. Swap them and one of the two is an error and the other is a different
question entirely — `HAVING max(ordered_on) >= DATE '2026-01-01'` would give you customers with more
than three orders **ever**, who also ordered at least once in 2026. That is a real question, and it
is not the one above.

Which is the honest distinction to carry away: the two clauses are not two ways of writing one
filter. Changing where a condition sits changes the meaning, not the style.

## A `HAVING` with no aggregate in it

This is legal and it is almost always a mistake:

```sql
SELECT   customer_id, count(*)
FROM     orders
GROUP BY customer_id
HAVING   customer_id <> 7;          -- works, and belongs in WHERE
```

It gives the right answer. It also groups every one of customer 7's orders, computes their count,
and then throws the group away. Filtering in `WHERE` would have skipped those rows before the
grouping started, which is less work — sometimes dramatically less, because a `WHERE` on an indexed
column can avoid reading the rows at all, and `HAVING` never can.

**The rule of thumb: if the condition can be written in `WHERE`, write it in `WHERE`.** `HAVING` is
for conditions that need an aggregate, and for nothing else.

## `HAVING` with no `GROUP BY`

Also legal, and occasionally exactly right:

```sql
SELECT sum(total) FROM orders WHERE customer_id = 7 HAVING sum(total) > 1000;
```

With no `GROUP BY`, the whole table is one group, so this returns **one row or none** — the total,
if it clears the threshold, and nothing at all if it does not. It is the one case where an
aggregate query can return zero rows, and it is a useful trick for "tell me only if it matters".

## Aliases, which are not portable here

```sql
SELECT   customer_id, count(*) AS orders
FROM     orders
GROUP BY customer_id
HAVING   orders > 3;             -- MySQL and SQLite: yes.  PostgreSQL: error.
```

MySQL and SQLite let you name the output column. PostgreSQL does not, even though it allows exactly
that in `GROUP BY` — which is inconsistent, and is the standard's fault rather than theirs. The
portable answers are to repeat the expression, or to compute the aggregate in a subquery and filter
it outside, which reads better as the query grows and is lesson 7's subject:

```sql
SELECT *
FROM  (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t
WHERE t.orders > 3;
```

Note what happened there: once the aggregate is a column of an inner query, the outer filter is an
ordinary `WHERE` again. `HAVING` is not a special kind of filter — it is a `WHERE` for a result you
have not finished computing yet.
