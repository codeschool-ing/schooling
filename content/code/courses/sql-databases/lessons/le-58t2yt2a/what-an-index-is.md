---
title: What an index actually is
version: 1
---

```sql
CREATE INDEX ON customers (email);
```

That statement does something physical. It builds **a second copy of the `email` column, kept
sorted, with a pointer beside each value to the row it came from.**

Not a setting. Not a hint to the planner. A structure, on disk, that has to be written and kept up
to date, and which is why everything else in this lesson is a trade rather than a free improvement.

> **The `orders` table changes shape from here on.** Lessons 1 to 7 ran against a shop with a few
> rows in it, where `ordered_on` is a `date` and every query returns instantly — which is the point
> when what is being taught is what a join means. An index is only visible against volume, so this
> lesson and the two after it run against the same shop with a million orders in it and a
> `placed_at timestamptz` in place of `ordered_on`. The captured output from here on is that
> database. Nothing about the SQL changes; what changes is that a scan now costs something you can
> read off the clock.

## Why sorted is the whole trick

Without it, finding `ana@example.com` in a million rows means reading a million rows. There is no
shortcut, because unsorted data has no shortcut — the row you want could be anywhere.

With it, the database opens the sorted copy in the middle, compares, and throws away half. Then
half of that. Twenty of those steps get you to one row out of a million, and thirty get you to one
out of a billion.

```
1 000 rows          ~10 steps
1 000 000 rows      ~20 steps
1 000 000 000 rows  ~30 steps
```

Look at that table for a second, because it explains the shape of everything that follows: **a
thousand times more data costs ten more steps.** A scan of the same table costs a thousand times
more work. That gap is what an index buys, and it is why the gain grows with the table rather than
staying the same.

## The B-tree, briefly

The sorted copy is not a flat list — a flat list would have to be rewritten every time a row was
inserted in the middle. It is a **B-tree**: a shallow tree of blocks, where each block holds a range
of values and pointers to the blocks below it.

```
                  [ f   m   s ]
                 /    |    |    \
        [a..e] [f..l] [m..r] [s..z]
```

Three or four levels is enough for hundreds of millions of rows, and each level is one block read.
An insert goes into the right block, and only splits a block when that block is full — so the tree
stays balanced without being rebuilt.

This is the default index type in every database in this course, and when somebody says "an index"
with no qualifier, they mean this one.

## What it can answer

Because the copy is sorted, it serves more than one shape of question:

```sql
WHERE email = 'ana@example.com'      -- find one value
WHERE email > 'm'                    -- find a position, then read forwards
WHERE created_at BETWEEN … AND …     -- find the start, read until the end
ORDER BY email                        -- read it in order, no sorting needed
WHERE email LIKE 'ana%'               -- a prefix is a range: 'ana' up to 'anb'
```

That last one is worth keeping. `LIKE 'ana%'` is a range scan and it is fast; `LIKE '%ana'` is not,
because the sorted copy is sorted by the beginning of the string and nothing about the end of it is
in order. It is the same fact, and the next section but one is a list of things that are the same
fact in disguise.

## And what it costs to follow

An index entry holds the value and a pointer, so answering `SELECT * FROM customers WHERE email =
…` is two steps: find the entry, then fetch the row it points at. That second fetch is a random
read somewhere else on disk, and on a query returning many rows it is the expensive part.

Which sets up two things this lesson comes back to. **A query that wants only the indexed columns
can skip the second step entirely** — that is the covering index. And **a query that would have to
follow the pointer for half the table is better off reading the table**, which is the honest reason
a planner ignores a perfectly good index.
