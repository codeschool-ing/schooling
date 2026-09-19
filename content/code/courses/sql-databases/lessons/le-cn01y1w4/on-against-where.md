---
title: ON against WHERE, which is the bug of this course
version: 1
---

This section is one bug. It produces no error, it looks like a working query, and it is the most
common mistake in SQL after forgetting that `NULL` exists.

You want every customer, with their orders from March.

```sql
SELECT c.name, o.id
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE  o.ordered_on >= '2026-03-01';
```

**Célia is gone.** So is every customer who did not order in March. The `LEFT JOIN` is still there
and it is doing nothing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"Two panels showing the same four joined rows: three real orders and Célia's invented row with nulls. On the left, the date condition is written in the ON clause: the row whose date is outside March goes dim, and Célia survives, marked that null compared with a date is unknown. On the right, the condition is in WHERE: the same row goes dim and Célia's row is highlighted as dropped, because unknown is not true. Notes read that the LEFT JOIN is still there in both and in the second it is doing nothing, with no error and no warning.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Every customer, with their orders from March. The two queries differ by where the date condition is written.</text><rect x=\"14\" y=\"44\" width=\"330\" height=\"194\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">ON o.customer_id = c.id AND o.ordered_on >= …</text><text x=\"28\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the join produced</text><rect x=\"28\" y=\"96\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Ana Lopes   1001  03-04</text><rect x=\"28\" y=\"120\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ana Lopes   1003  02-11</text><rect x=\"28\" y=\"144\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Bruno Sá    1002  03-20</text><rect x=\"28\" y=\"168\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Célia Reis  NULL   NULL</text><text x=\"28\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">her NULL >= date is unknown</text><text x=\"28\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the condition ran during the pairing: Célia keeps her invented row</text><rect x=\"376\" y=\"44\" width=\"330\" height=\"194\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"541\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">ON o.customer_id = c.id  …  WHERE o.ordered_on >= …</text><text x=\"390\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the join produced</text><rect x=\"390\" y=\"96\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Ana Lopes   1001  03-04</text><rect x=\"390\" y=\"120\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"398\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ana Lopes   1003  02-11</text><rect x=\"390\" y=\"144\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Bruno Sá    1002  03-20</text><rect x=\"390\" y=\"168\" width=\"240\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Célia Reis  NULL   NULL</text><text x=\"390\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">her NULL >= date is unknown</text><text x=\"390\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the condition ran after: Célia’s invented row fails it and is dropped</text><text x=\"14\" y=\"260\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The LEFT JOIN is still there in both, and in the second one it is doing nothing at all.</text><text x=\"14\" y=\"278\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">No error, no warning, and a result that looks like a working query.</text></svg>", "caption": "Both queries are valid, both run, and one of them silently answers a different question. The clause the condition sits in is the whole difference."}
```

## Why

Go back to the order the clauses run, from lesson 4. The join runs first, and it does its job:

```
 Ana Lopes  | 1001
 Ana Lopes  | 1003
 Bruno Sá   | 1002
 Célia Reis | NULL      <- the invented row
```

Then `WHERE` runs on that result. Célia's `o.ordered_on` is `NULL`, because the whole right-hand
side of her row is null. `NULL >= '2026-03-01'` is **unknown**, and `WHERE` keeps rows where the
condition is true.

Her row is discarded. The `LEFT JOIN` produced it and the `WHERE` threw it away.

> **A condition on the right-hand table in `WHERE` turns a `LEFT JOIN` into an `INNER JOIN`.**

## The fix, which is one word moved

```sql
SELECT c.name, o.id
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
                  AND o.ordered_on >= '2026-03-01';
```

`ON` decides **which pairs are made**. `WHERE` decides **which rows survive afterwards**. Putting
the condition in `ON` means Célia never gets a partner in the first place — so she gets the invented
null row, and she is in the answer.

```
 Ana Lopes  | 1004
 Bruno Sá   | NULL      <- ordered, but not in March
 Célia Reis | NULL      <- never ordered
```

Read those last two rows, because they are the point: **the query can no longer tell them apart**
from the output alone, and often that is fine. When it is not, you need a column that says which
case it is, and lesson 6's aggregates are how.

## The rule, and the one exception

> **On a `LEFT JOIN`: conditions about the right-hand table go in `ON`. Conditions about the
> left-hand table go in `WHERE`.**

`WHERE c.city = 'Porto'` is about customers — the left side — so it belongs in `WHERE` and behaves
exactly as you expect.

And the exception, which is a technique rather than a mistake:

```sql
WHERE o.id IS NULL
```

That is deliberate. It keeps only the rows where the join found nothing — an **anti-join**, which is
the `finding-what-is-missing` section. It turns the `LEFT JOIN` into a filter for absence, and it
is the one time you want a `WHERE` on the right-hand table.

## On an inner join it makes no difference

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id AND o.total > 50
FROM customers c JOIN orders o ON o.customer_id = c.id WHERE o.total > 50
```

Identical results. There is no invented row to lose, so filtering during and filtering after come
to the same thing.

**Which is exactly why the bug survives.** Somebody learns joins on inner joins, learns that `ON`
and `WHERE` are interchangeable, and carries that to a `LEFT JOIN` where it is false. The rule is
not "it depends" — it is that the two clauses have always meant different things, and the inner join
is the case where the difference does not show.

## How to catch it

**Count the left-hand table before and after.** If `customers` has 3 rows and your `LEFT JOIN`
query returns 2, you lost one and the `WHERE` is where it went.

**Look for right-hand columns in `WHERE`.** Reading any query with a `LEFT JOIN`, scan the `WHERE`
for a column of the right-hand table. Every one is either this bug or a deliberate `IS NULL`, and
you should be able to say which.
