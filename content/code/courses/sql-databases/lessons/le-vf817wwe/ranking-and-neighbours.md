---
title: Ranking, and looking at the row before this one
version: 1
---

The functions in this section exist only as window functions — there is no `GROUP BY` version of
them, because every one is about a row's place among its neighbours. They are also the ones you
will use most, so it is worth learning the small differences properly.

## Three ways to number rows

```sql
SELECT name, score,
       row_number() OVER (ORDER BY score DESC) AS n,
       rank()       OVER (ORDER BY score DESC) AS r,
       dense_rank() OVER (ORDER BY score DESC) AS d
FROM   players;
```

```
name    score   n   r   d
Ana      90     1   1   1
Bruno    85     2   2   2
Celia    85     3   2   2
Dario    70     4   4   3
```

- **`row_number()`** numbers every row, 1, 2, 3, with no ties — Bruno and Celia get 2 and 3, and
  which of them gets which is arbitrary unless you add a tiebreaker to the `ORDER BY`.
- **`rank()`** gives ties the same number and then skips: 1, 2, 2, **4**. This is how sport ranks
  things, and it is what somebody means by "joint second".
- **`dense_rank()`** gives ties the same number and does not skip: 1, 2, 2, **3**.

Pick by what you are doing. Displaying a leaderboard: `rank()`. Taking exactly three rows:
`row_number()`, because `rank()` can return four rows for "the top three" and your page layout will
not expect it.

These three ignore the frame entirely — the frame clause changes nothing for them, so writing one
is noise.

## The top N of each group

The question lesson 4 could not answer, and lesson 5 answered with a self-join and a correlated
subquery. Here it is properly:

```sql
SELECT * FROM (
    SELECT o.*,
           row_number() OVER (PARTITION BY customer_id ORDER BY placed_at DESC) AS n
    FROM   orders o
) t
WHERE t.n <= 3;
```

The three most recent orders for each customer. Change `3` to `1` and it is "the latest order per
customer", which is the single most common shape in this entire lesson — every dashboard that shows
a current state over a table of events is this query.

PostgreSQL has a shorter spelling for the `n = 1` case, `DISTINCT ON`, which lesson 4 mentioned and
promised a portable alternative to. This is it. `DISTINCT ON` is terser where you have it; the
window version works everywhere and extends to three without being rewritten.

The wrapping is not optional, for the reason the last section gave: you cannot filter on a window
function in `WHERE`, because it has not run yet.

## Deduplication, which is the same query

Once you can number rows within a group, removing duplicates is one condition:

```sql
DELETE FROM contacts
WHERE  id IN (
    SELECT id FROM (
        SELECT id, row_number() OVER (PARTITION BY lower(email) ORDER BY created_at) AS n
        FROM   contacts
    ) t
    WHERE t.n > 1
);
```

Partition by what should have been unique, order by which one you want to keep, delete the rest.
Run the `SELECT` first and look at it — this is a `DELETE`, and lesson 8's transactions are the
safety net you want around it.

Afterwards, add the unique constraint lesson 3 described, or you will be running this again in six
months.

## The row before and the row after

`lag()` reaches backwards, `lead()` forwards:

```sql
SELECT month, revenue,
       lag(revenue)  OVER (ORDER BY month) AS previous,
       revenue - lag(revenue) OVER (ORDER BY month) AS change
FROM   monthly;
```

Month-on-month change, without joining the table to itself on `month - 1` — which breaks on a month
with no rows, where `lag` simply takes the previous row that exists.

The first row has nothing before it, so `lag` is null there and `change` is null too. Supply a
default if you would rather not:

```sql
lag(revenue, 1, 0) OVER (ORDER BY month)    -- offset 1, default 0 at the edge
```

The same pair answers "how long between these events", which is otherwise awkward:

```sql
SELECT user_id, at,
       at - lag(at) OVER (PARTITION BY user_id ORDER BY at) AS since_previous
FROM   events;
```

And `lead` is how you find gaps: a row whose `lead(at)` is more than an hour away is the last event
of a session.

## `first_value`, `last_value`, and the trap in the second one

```sql
first_value(total) OVER (PARTITION BY customer_id ORDER BY placed_at)   -- their first order
last_value (total) OVER (PARTITION BY customer_id ORDER BY placed_at)   -- NOT their last one
```

`last_value` returns the current row's own total, every time. It is the frame default again: with
an `ORDER BY` the frame ends at the current row, so the last row it can see **is** the current row.

Two fixes, and the second is the one to prefer:

```sql
last_value(total) OVER (PARTITION BY customer_id ORDER BY placed_at
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)

first_value(total) OVER (PARTITION BY customer_id ORDER BY placed_at DESC)
```

The second says what it means without a frame clause, and is harder to get wrong later.

## `ntile`, for buckets

```sql
ntile(4) OVER (ORDER BY spent DESC) AS quartile
```

Splits the rows into four groups of as equal a size as it can manage, numbered 1 to 4. It is how
you get quartiles or deciles without computing any boundaries yourself. Be clear about what it
does: it divides by **count of rows**, not by value, so the boundary between quartile 1 and 2 falls
wherever the counts say — two customers who spent almost the same amount can land either side of
it.

## What they replace

Every function here has a pre-window version that still turns up in old code: a self-join to the
same table on "the previous row", a correlated subquery per column, a second query and a loop in
the application. Those versions are slower, because they read the table more than once, and they
are longer. When you meet one, the rewrite is usually a single window function — and the way to
recognise the opportunity is the phrase in the requirement: *previous, next, running, rank, top per,
compared with, since last.* Every one of those is in this section.
