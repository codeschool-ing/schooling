---
title: NULL is not a value, and this is where people get hurt
version: 2
---

Every column that is not declared `NOT NULL` can hold `NULL`, and `NULL` behaves unlike anything
else in SQL. It is worth a section of its own in the first lesson, before you have written a
single query, because the misunderstanding is silent: queries do not fail, they just quietly
return the wrong rows.

**`NULL` does not mean zero. It does not mean an empty string. It means *unknown*.**

| row | city | what it says |
|---|---|---|
| Ana | `'Porto'` | her city is Porto |
| Bruno | `''` | her city is the empty string — which is a value, and a strange one |
| Célia | `NULL` | **nobody knows her city** |

Those are three different states and the third is not a value at all. It is the absence of one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three rows, each showing a value entering the condition price greater than twenty and the verdict that comes out. Price thirty gives TRUE and is kept. Price five gives FALSE and is dropped. Price null gives UNKNOWN, highlighted, and is also dropped. A note reads that this is three-valued logic and that the negation of unknown is unknown, so NOT does not bring the null row back.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">WHERE keeps a row on one verdict out of three, and a null produces the third one.</text><rect x=\"14\" y=\"48\" width=\"150\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">price = 30</text><path d=\"M168 63 L224 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224 63 L216.0 67.0 L216.0 59.0 Z\" fill=\"var(--wire)\"></path><rect x=\"228\" y=\"48\" width=\"130\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">price > 20</text><path d=\"M362 63 L418 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M418 63 L410.0 67.0 L410.0 59.0 Z\" fill=\"var(--wire)\"></path><rect x=\"422\" y=\"48\" width=\"120\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"482\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">TRUE</text><path d=\"M546 63 L592 63\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M592 63 L584.0 67.0 L584.0 59.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"600\" y=\"63\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">kept</text><rect x=\"14\" y=\"92\" width=\"150\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"89\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">price = 5</text><path d=\"M168 107 L224 107\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224 107 L216.0 111.0 L216.0 103.0 Z\" fill=\"var(--wire)\"></path><rect x=\"228\" y=\"92\" width=\"130\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">price > 20</text><path d=\"M362 107 L418 107\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M418 107 L410.0 111.0 L410.0 103.0 Z\" fill=\"var(--wire)\"></path><rect x=\"422\" y=\"92\" width=\"120\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"482\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">FALSE</text><path d=\"M546 107 L592 107\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M592 107 L584.0 111.0 L584.0 103.0 Z\" fill=\"var(--wire)\"></path><text x=\"600\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dropped</text><rect x=\"14\" y=\"136\" width=\"150\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">price = NULL</text><path d=\"M168 151 L224 151\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M224 151 L216.0 155.0 L216.0 147.0 Z\" fill=\"var(--wire)\"></path><rect x=\"228\" y=\"136\" width=\"130\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">price > 20</text><path d=\"M362 151 L418 151\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M418 151 L410.0 155.0 L410.0 147.0 Z\" fill=\"var(--wire)\"></path><rect x=\"422\" y=\"136\" width=\"120\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"482\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">UNKNOWN</text><path d=\"M546 151 L592 151\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M592 151 L584.0 155.0 L584.0 147.0 Z\" fill=\"var(--wire)\"></path><text x=\"600\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dropped</text><text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">This is three-valued logic: true, false, and unknown. Comparing anything with a null gives the third.</text><text x=\"14\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">So NOT (price > 20) does not bring the null row back — the negation of unknown is unknown.</text></svg>", "caption": "The third verdict is the whole difficulty. A row does not fail the condition — the condition has no answer about it, and WHERE keeps only the rows it said yes to."}
```

## Unknown compared with anything is unknown

This is the whole thing, and every surprise below follows from it:

```sql
SELECT NULL = NULL;
```

```
 ?column?
----------
 (null)
```

Not `true`. **`NULL = NULL` is not true**, because "is this unknown thing the same as that unknown
thing?" cannot be answered by anybody who does not know either of them. The answer is itself
unknown.

The same for everything else:

```sql
SELECT NULL = 5,  NULL <> 5,  NULL > 5,  NULL + 1,  'a' || NULL;
```

```
 ?column? | ?column? | ?column? | ?column? | ?column?
----------+----------+----------+----------+----------
 (null)   | (null)   | (null)   | (null)   | (null)
```

Every comparison against an unknown is unknown, and every arithmetic on an unknown is unknown. SQL
has **three** truth values — true, false and unknown — and this is called three-valued logic.

## Which is why `WHERE` loses rows

A `WHERE` clause keeps rows where the condition is **true**. Not "not false" — true. Unknown is
not true, so the row is dropped.

Suppose ten customers, of whom three have `city = NULL`:

```sql
SELECT count(*) FROM customers WHERE city = 'Porto';      -- 4
SELECT count(*) FROM customers WHERE city <> 'Porto';     -- 3
```

Four plus three is seven, and there are ten customers. **The three with an unknown city are in
neither answer**, and nothing told you. Both queries are correct; the arithmetic you did in your
head was not.

This is the shape of the bug in the wild. A report of "customers outside Porto" quietly omits
everybody whose city was never filled in, the number is a bit low, and it stays a bit low for
years.

## So you ask a different question

There is a dedicated operator, and it is the only way:

```sql
SELECT count(*) FROM customers WHERE city IS NULL;        -- 3
SELECT count(*) FROM customers WHERE city IS NOT NULL;    -- 7
```

`IS NULL` and `IS NOT NULL` ask about the *state* rather than comparing values, so they always
answer true or false. `= NULL` is not an error and not a syntax mistake — it is a valid expression
that is never true, which is far worse, because nothing complains.

To include the unknowns deliberately:

```sql
SELECT count(*) FROM customers WHERE city <> 'Porto' OR city IS NULL;   -- 6
```

Now it is six and three and one, which adds to ten.

## The places it bites that nobody warns you about

**Uniqueness lets several `NULL`s through.** A `UNIQUE` column may hold many `NULL`s, because two
unknowns are not known to be equal:

```sql
CREATE TABLE people (tax_id text UNIQUE);
INSERT INTO people VALUES (NULL), (NULL), (NULL);   -- all three are accepted
```

Correct by the logic, and surprising the first time. If you need at most one row without a tax id,
`UNIQUE` is not the tool.

**Aggregates skip it, except one.** `count(*)` counts rows; `count(city)` counts rows where `city`
is not null; `avg`, `sum`, `min` and `max` all ignore nulls. So the average of `10, 20, NULL` is
**15, not 10** — three values, two of them known, and the unknown is not treated as a zero.

**`NOT IN` collapses entirely.** This one is the nastiest:

```sql
SELECT * FROM customers WHERE id NOT IN (1, 2, NULL);
```

Zero rows. Always. Whatever is in the table. `id NOT IN (1, 2, NULL)` unfolds to `id <> 1 AND id
<> 2 AND id <> NULL`, and that last one is unknown, so the whole `AND` can never be true. A
subquery that returns one unaccounted-for `NULL` turns a `NOT IN` into a query that returns
nothing and reports no error. Lesson 7 shows what to write instead.

**Sorting has to be told.** Nulls sort last by default in PostgreSQL's ascending order and first
in descending — and other databases choose differently. `ORDER BY city NULLS FIRST` says what you
meant.

## The lesson for modelling, which is the reason this is in lesson 1

Every one of the surprises above is avoided by not having the `NULL` in the first place. So:

> **Declare `NOT NULL` on everything, and remove it only where you can say out loud what an empty
> one means.**

This is the opposite of how most people start, which is to allow nulls everywhere "for
flexibility" and add constraints later. Later never comes, and by then the table holds a hundred
thousand rows of which some have unknown cities for reasons nobody can reconstruct.

And when a column genuinely is optional, be sure that `NULL` is what you mean:

- A delivery date that has not happened yet — **`NULL` is right**, it is genuinely unknown.
- A middle name somebody does not have — **`NULL` is arguable**; some would use an empty string,
  because "has no middle name" is known rather than unknown. Pick one and be consistent, because a
  table holding both is a table where every query needs two conditions.
- A quantity of zero — **`NULL` is wrong.** Zero is a number and a perfectly good answer. Storing
  it as unknown throws away a fact you had.

The habit to build: when you write a nullable column, write down in one sentence what a `NULL`
there means. If the sentence is hard to write, the column should probably be `NOT NULL`.
