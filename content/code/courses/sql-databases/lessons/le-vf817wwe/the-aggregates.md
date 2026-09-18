---
title: The aggregate functions, and the one thing they all do with NULL
version: 1
---

An aggregate function takes many rows and returns one value. That is the whole idea, and the five
you will use are unremarkable:

```sql
SELECT count(*)      AS orders,
       sum(total)    AS revenue,
       avg(total)    AS average,
       min(ordered_on) AS first_order,
       max(ordered_on) AS last_order
FROM   orders;
```

One row comes back. Not one row per order — **one row, for the whole table**, because there is no
`GROUP BY` and the next section is what happens when there is.

`min` and `max` are not only for numbers: they work on anything the database can order, which
includes text and dates. `min(name)` is the alphabetically first name, and `max(ordered_on)` is the
most recent order, which is how you ask "when did this customer last buy" without sorting anything
yourself.

## The rule underneath all of them

> **Every aggregate ignores the rows where its argument is null. Every one except `count(*)`.**

That single sentence produces most of this section, and the most expensive consequence is one
people carry for years without noticing.

Ten ratings, three of them not yet given:

```sql
SELECT count(*)      FROM reviews;           -- 10
SELECT count(rating) FROM reviews;           -- 7
SELECT sum(rating)   FROM reviews;           -- 28
SELECT avg(rating)   FROM reviews;           -- 4.0
```

`28 / 10` is 2.8. The average says 4.0. Neither number is wrong — they answer different questions,
and only one of them was asked out loud.

```
avg(rating)  =  sum(rating) / count(rating)      the average of the ratings that exist
28 / count(*)                                    the average if a missing rating were a zero
```

**And nothing in the output says which rows it counted.** A column that is 99% populated gives an
average that is very nearly right, so the defect stays invisible until the month somebody adds a
new field and the column is 40% populated. Then the average moves and nobody can say why.

If a missing value really should count as zero, say so, and say it where a reader can see it:

```sql
SELECT avg(coalesce(rating, 0)) FROM reviews;    -- 2.8
```

Now the claim is in the query rather than in somebody's head.

## `count(*)` against `count(column)`

They are different functions that happen to share a name, and the difference is exactly the rule
above:

| written | counts |
|---|---|
| `count(*)` | rows — it has no argument, so there is nothing to be null |
| `count(rating)` | rows where `rating` is not null |
| `count(DISTINCT rating)` | the distinct values, nulls not among them |
| `count(1)` | rows, identically to `count(*)`, and no faster |

`count(1)` is worth one sentence because you will meet it in old code and be told it is quicker.
It is not, in any database still maintained; the planner treats it the same. Write `count(*)`,
which says what it means.

## Sum over no rows is not zero

The asymmetry that breaks reports:

```sql
SELECT count(*), sum(total) FROM orders WHERE customer_id = 999;
```

For a customer with no orders that is `0` and **`NULL`** — not `0` and `0`. `count` starts at zero
and stays there; `sum` has nothing to add and has no opinion, so it returns unknown.

That is defensible and it still lands in a division, a total, or a template that prints the word
`null` to a customer. The fix is one function:

```sql
SELECT coalesce(sum(total), 0) FROM orders WHERE customer_id = 999;   -- 0
```

Use it whenever a sum is going anywhere except your own eyes. The same applies to `avg`, `min` and
`max`, which are all null over an empty set.

And note the shape of it: **an aggregate query with no `GROUP BY` always returns exactly one row**,
even when the table is empty or the `WHERE` matched nothing. Zero rows in, one row out. This is the
opposite of everything else in SQL and it is occasionally useful — a dashboard query that must
render a figure will always have a figure to render, once you have wrapped it in `coalesce`.

## Integers divide like integers

```sql
SELECT sum(quantity) / count(*) FROM order_lines;
```

If both are integers, some databases give you integer division: 7 items over 2 orders is `3`, not
`3.5`, and the rounding is silent. `avg()` does not have this problem — it promotes to a decimal
type — which is one more reason to use it rather than dividing by hand. When you must divide,
cast:

```sql
SELECT sum(quantity)::numeric / count(*) FROM order_lines;   -- PostgreSQL
SELECT sum(quantity) * 1.0  / count(*) FROM order_lines;     -- portable
```

## The others, briefly

Worth knowing they exist, because each replaces a loop somebody would otherwise write in
application code:

```sql
string_agg(name, ', ' ORDER BY name)   -- the names, joined into one string
array_agg(id)                          -- the ids, as one array
bool_or(is_paid)                       -- true if any row is
bool_and(is_paid)                      -- true only if every row is
stddev(total), variance(total)         -- the spread, not just the middle
```

`string_agg` is the one you will reach for first: "the tags on this article, comma separated" is
one line here and a second query plus a loop anywhere else. MySQL and MariaDB spell it
`group_concat`; SQLite also `group_concat`. The `ORDER BY` inside the parentheses is not a typo —
an aggregate that builds a list can be told what order to build it in, and without it the order is
whatever the database found convenient.
