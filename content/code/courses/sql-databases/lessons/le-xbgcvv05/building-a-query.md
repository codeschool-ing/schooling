---
title: Building one, and reading somebody else's
version: 1
---

Everything in this lesson, as the way you actually work rather than as a list of clauses.

## Build it outwards, one clause at a time

Nobody writes a correct query in one go, and trying to is how you end up with one that returns
nothing and gives you no idea which part is wrong.

**Start with the rows.**

```sql
SELECT * FROM products LIMIT 10;
```

You are checking that the table is what you think it is, and the `LIMIT` is so that a mistake
costs nothing.

**Add one condition and check the count.**

```sql
SELECT count(*) FROM products WHERE category = 'kitchen';
```

`count(*)` rather than the rows, because a number tells you immediately whether the filter is doing
something. Zero means the filter is wrong, or the data is not what you expected, and either way you
found out on one condition rather than on six.

**Add the next one, and watch the number move.**

```sql
SELECT count(*) FROM products WHERE category = 'kitchen' AND price > 20;
```

If the number does not change, that condition is doing nothing. If it drops to zero, that condition
is the problem. This is the entire debugging technique, and it works because you added one thing.

**Then the columns, then the order, then the limit.**

```sql
SELECT name, price
FROM   products
WHERE  category = 'kitchen' AND price > 20
ORDER BY price DESC, id
LIMIT  20;
```

The `, id` is the previous section's rule, and adding it at the same moment as the `LIMIT` is how
you stop forgetting it.

## Checking an answer you cannot verify by eye

A query over a thousand rows gives you a number you have no way of knowing is right. Three things
that catch most errors:

**Count both sides of a filter.** If `category = 'kitchen'` gives 40 and `category <> 'kitchen'`
gives 55, and the table has 100 rows, five rows are in neither — and they are the nulls, from the
`null-in-a-query` section. The arithmetic not adding up is the signal.

**Ask for the extremes.** `ORDER BY price DESC LIMIT 5` and `ORDER BY price LIMIT 5`. If the most
expensive product is €4,000,000 or the cheapest is negative, the filter is not the problem and the
data has something in it you did not know about.

**Look at a row you can verify by hand.** One customer, one order, one invoice — something you can
check against another source. A query that is wrong in general is usually wrong on a single row you
can read.

## Reading somebody else's

Read the clauses in the order they run, not the order they are written:

1. **`FROM`** — what is this about? One table, or several joined, which is lesson 5.
2. **`WHERE`** — which rows survive? This is where the business rule usually is.
3. **`GROUP BY` / `HAVING`** — is this about groups rather than rows? Lesson 6.
4. **`SELECT`** — what comes out, and what is computed.
5. **`ORDER BY` / `LIMIT`** — is there a limit with no total order? That is a bug, and it is the one
   worth looking for first.

And two things to be suspicious of on sight, both from this lesson:

- **`DISTINCT`** — where did the duplicates come from?
- **a function wrapped around a filtered column** — `WHERE lower(email) = …`, `WHERE
  extract(year FROM created_at) = …`. It works and it cannot use an index.

## What this lesson did not cover

Named, because lesson 2's rule about boundaries applies to a lesson as much as to a course: a
boundary stated is legitimate, and one that is only an absence is a hole.

- **More than one table.** Everything here reads a single table. Lesson 5.
- **Summarising.** Counts, totals and averages per group. Lesson 6.
- **Queries inside queries.** `EXISTS` appeared twice in this lesson as the right answer to
  something, and is explained in lesson 7.
- **Changing data.** `INSERT`, `UPDATE`, `DELETE` — they share `WHERE` with `SELECT`, and the
  difference is that a mistake is not recoverable by rerunning it. Lesson 8, with transactions,
  which is the right place because that is what makes a mistake recoverable.
- **Why a query is slow.** Lessons 9 and 10. This lesson has pointed at three places where the
  shape of a condition decides whether an index can be used; that is the whole of what to carry
  until then.

## The six rules from this lesson

1. **It runs `FROM`, `WHERE`, `SELECT`, `ORDER BY`, `LIMIT`** — which is why an alias works in one
   place and not another.
2. **Name the columns**, not `*`, in anything that is not a terminal.
3. **Parenthesise `AND` with `OR`.**
4. **Leave the column bare** on one side of a comparison.
5. **`LIMIT` needs a total `ORDER BY`** — end it on the key.
6. **`DISTINCT` is a question**, not an answer: where did the duplicates come from?
