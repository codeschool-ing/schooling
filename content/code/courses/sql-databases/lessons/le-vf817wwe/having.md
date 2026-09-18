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

```
FROM      which rows exist
WHERE     throw rows away          <- no aggregates here: none have been computed
GROUP BY  sort them into piles
HAVING    throw piles away         <- aggregates here, because now they exist
SELECT    compute the columns
ORDER BY  sort the result
LIMIT     take some
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
