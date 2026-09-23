---
title: You added the index and nothing changed
version: 2
---

This is the section that saves the most time, because every item on the list looks like a bug in
the database and is not one. The index exists, the query names the column, and the plan reads the
whole table anyway.

There are about seven reasons. Six are things you did, and the seventh is the planner being right.

## A function around the column

```sql
WHERE lower(email) = 'ana@example.com'      -- index on (email): unused
WHERE date(created_at) = DATE '2026-03-01'  -- index on (created_at): unused
WHERE coalesce(price, 0) > 100              -- index on (price): unused
```

The index holds `email`, sorted. It does not hold `lower(email)`, and the database has no way to
work out where `lower(email)` would sort without computing it for every row — which is the scan you
were trying to avoid.

Lesson 4 warned about the third of these and promised the mechanism here. It is this: **wrap a
column in anything and the sorted copy of that column stops applying.**

Two fixes, and prefer the second where it exists:

```sql
CREATE INDEX ON customers (lower(email));           -- index the expression instead

WHERE created_at >= DATE '2026-03-01'               -- rewrite as a range on the bare column
  AND created_at <  DATE '2026-03-02';
```

The rewrite is better when it is available, because it uses the index you already have and it stays
correct across time zones, which `date(created_at)` quietly does not.

## `LIKE` with a leading wildcard

```sql
WHERE name LIKE 'ana%'     -- fast: a prefix is a range in a sorted list
WHERE name LIKE '%ana'     -- a scan, and no ordinary index can help
WHERE name LIKE '%ana%'    -- the same
```

The copy is sorted from the beginning of the string. Everything beginning with `ana` sits together;
everything *ending* with it is scattered from A to Z. There is no arrangement of a B-tree that
fixes that, so the answer is a different kind of index — a trigram index, which the
`the-other-types` section covers.

## A type that does not match

```sql
WHERE phone = 5551234      -- phone is text
```

The engine has to make the types agree, and which side it converts decides everything. Convert the
literal and the index works. Convert the **column** — which is what MySQL does when comparing a
string column to a number — and every row has to be converted to be compared, so the index is out
and the scan is in. It is one missing pair of quotes and it is invisible in code review.

The same happens across a join when a foreign key is `integer` on one side and `bigint` or `text`
on the other, which is a schema mistake that hides as a performance mystery for years.

## The column inside arithmetic

```sql
WHERE price * 1.1 > 100        -- unused
WHERE price > 100 / 1.1        -- the same question, and the index applies
```

Same rule as the function: the sorted values are `price`, not `price * 1.1`. Move the arithmetic to
the other side of the comparison and the index comes back. **Keep the column bare on its side of
the operator** is the habit that covers this one and the first one together.

## `OR` across different columns

```sql
WHERE email = 'a@b.c' OR phone = '555'
```

Two indexes, two conditions, and neither one alone narrows the answer. PostgreSQL can combine them
with a bitmap of both, which works; other engines often give up and scan. Where it matters, two
queries joined by `UNION` will each use their own index, and it reads worse and runs better.

`NOT` and `<>` are the extreme case of the same thing: *"everything except this"* usually matches
most of the table, and most of the table is a scan.

## The values are not selective enough

```sql
WHERE active        -- 600 000 of a million rows
```

Covered in the last section, and it belongs on this list because it is the one people argue with.
The index is fine. Using it would mean following six hundred thousand pointers to scattered pages,
and reading the table straight through is faster. **The planner is not ignoring your index; it
priced both plans and picked one.**

The partial index is the tool for the other half of this — the 3% of rows where `status =
'pending'` — and it has its own section.

## The statistics are out of date

The planner does not count rows; it estimates them from statistics gathered by a background job. If
those statistics say a column has three distinct values and it now has three million, the estimate
is wrong and the plan follows the estimate.

```sql
ANALYZE customers;      -- recollect them now
```

This is the reason behind *"it was fast yesterday"* after a bulk import: the data changed shape
faster than the statistics did. It is also the first thing to check before believing anything else
on this list.

## Seeing which one it is

Every item above is visible rather than guessable:

```sql
EXPLAIN SELECT … ;
```

It prints the plan, it says `Seq Scan` or `Index Scan`, and it says what it expected the row counts
to be. Lesson 10 is entirely about reading that output, and it is the difference between this list
being a set of rules to memorise and a set of things you can check in ten seconds.
