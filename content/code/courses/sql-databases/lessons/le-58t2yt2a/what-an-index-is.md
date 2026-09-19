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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"A B-tree index on the email column. At the top, one root block holding three separator letters, f, m and s. Four arrows lead from it to four leaf blocks, covering a to e, f to l, m to r and s to z, drawn in order from left to right. The arrow to the first leaf and the leaf itself are highlighted, and below it that leaf is opened: three e-mail addresses in alphabetical order, each with a pointer beside it. A dashed arrow from the first pointer crosses to a separate block on the right holding the row itself, labelled one random read. Along the bottom: a thousand rows take about ten steps, a million about twenty, a billion about thirty, and three or four levels is enough for hundreds of millions of rows, each level costing one block read.\"><text x=\"14\" y=\"20\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">CREATE INDEX ON customers (email)</text><rect x=\"250\" y=\"38\" width=\"220\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M323 38 L323 68\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M396 38 L396 68\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"286\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">f</text><text x=\"359\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">m</text><text x=\"432\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">s</text><text x=\"240\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">root</text><path d=\"M360 68 L96 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><rect x=\"14\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"96\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">a … e</text><path d=\"M360 68 L272 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"190\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">f … l</text><path d=\"M360 68 L448 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"366\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"448\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">m … r</text><path d=\"M360 68 L624 104\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"542\" y=\"104\" width=\"164\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">s … z</text><text x=\"706\" y=\"146\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">leaves, in order</text><path d=\"M96 132 L96 158\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><rect x=\"14\" y=\"158\" width=\"250\" height=\"82\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ana@example.com</text><text x=\"24\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">anders@example.com</text><text x=\"24\" y=\"214\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bea@example.com</text><circle cx=\"244\" cy=\"174\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"244\" cy=\"194\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"244\" cy=\"214\" r=\"3\" fill=\"var(--amber)\"></circle><text x=\"24\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">value + pointer</text><path d=\"M250 174 L452 174\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></path><path d=\"M452 174 L444 170 L444 178 Z\" fill=\"var(--amber)\"></path><text x=\"351\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">one random read</text><rect x=\"456\" y=\"158\" width=\"250\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"466\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana  ana@example.com  BR</text><text x=\"466\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the row on disk</text><path d=\"M14 258 L706 258\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"14\" y=\"274\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 000 rows ~10 steps   ·   1 000 000 ~20   ·   1 000 000 000 ~30</text><text x=\"14\" y=\"292\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three or four levels for hundreds of millions of rows, and each level is one block read</text></svg>", "caption": "Each level is one block read, so the depth barely moves as the table grows. The dashed arrow is the second step, and it is the expensive one."}
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
