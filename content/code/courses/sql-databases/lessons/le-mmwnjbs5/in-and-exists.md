---
title: IN, EXISTS, and the one that returns nothing
version: 1
---

Two ways to ask "is this row in that set", and they look interchangeable:

```sql
SELECT * FROM products p WHERE p.category_id IN     (SELECT id FROM categories WHERE active);
SELECT * FROM products p WHERE EXISTS (SELECT 1 FROM categories c WHERE c.id = p.category_id AND c.active);
```

Same answer, most days. The difference is what each one asks:

- **`IN` compares values.** It builds the set the subquery returns and tests membership.
- **`EXISTS` asks whether a row exists.** It looks at no columns at all — the `SELECT 1` is there
  because something has to be written, and `SELECT *` is identical. Anyone who tells you one is
  faster than the other is repeating folklore; every planner discards that list.

For the positive form, pick whichever reads better. For the negative form, they are not the same
thing, and lesson 4 promised this section would say why.

## `NOT IN` with a null returns no rows at all

```sql
SELECT * FROM products WHERE category_id NOT IN (1, 2, NULL);
```

Zero rows, whatever the table holds, for ever. Unfolding it is the whole explanation:

```
category_id NOT IN (1, 2, NULL)
category_id <> 1  AND  category_id <> 2  AND  category_id <> NULL
                                              └─ unknown, always
```

An `AND` with an unknown in it can be false, or unknown, and never true. So no row qualifies. It is
correct SQL, correct three-valued logic, and an empty answer that looks like a finding.

Nobody writes a literal `NULL` in a list. Subqueries produce them constantly:

```sql
SELECT * FROM products
WHERE  category_id NOT IN (SELECT category_id FROM discontinued_lines);
```

One row of `discontinued_lines` with a null `category_id` — a column nobody thought to constrain —
and this query returns nothing. It worked in testing, it worked for a year, and it stops the day
somebody inserts a row with a field left blank. **No error is raised and no warning is printed.**

## `NOT EXISTS` cannot do this

```sql
SELECT * FROM products p
WHERE  NOT EXISTS (SELECT 1 FROM discontinued_lines d WHERE d.category_id = p.category_id);
```

The comparison is inside, one row at a time. `d.category_id = p.category_id` against a null is
unknown, so that row does not match, so it does not contribute an existence — and the product is
kept, which is the right answer. Nothing propagates outwards, because `EXISTS` returns true or
false and never unknown.

> **Use `NOT EXISTS` for "not in that set", unless you have proved the column is not nullable.**

And "proved" means a `NOT NULL` constraint, from lesson 3, rather than a belief. A belief about
nullability is exactly what this bug is made of.

## The third form, which you already know

Lesson 5's anti-join says the same thing again:

```sql
SELECT p.*
FROM   products p
LEFT JOIN discontinued_lines d ON d.category_id = p.category_id
WHERE  d.category_id IS NULL;
```

Keep every product, pair where possible, then keep only the rows where the pairing failed. It is
immune to the null trap too, for the same reason `NOT EXISTS` is — the comparison happens in the
`ON`, per row.

Three spellings of one question, then:

| | null-safe | reads as |
|---|---|---|
| `NOT IN (subquery)` | **no** | membership of a set |
| `NOT EXISTS (correlated)` | yes | is there one of these |
| `LEFT JOIN … IS NULL` | yes | pair them, keep the failures |

The middle one says what it means most directly, which is why it is the habit worth forming. The
third turns up in older code and in query builders that have no other way to express it.

## `ANY` and `ALL`

Two operators most people never write and everybody eventually reads:

```sql
x = ANY (SELECT …)      -- identical to x IN (SELECT …)
x <> ALL (SELECT …)     -- identical to x NOT IN (SELECT …), null trap and all
x > ALL (SELECT price FROM products WHERE category_id = 3)
```

The last one is the reason they exist: a comparison other than equality against every row of a set.
*"Costs more than everything in category 3"* is one line here and a subquery with `max()` otherwise
— and the two differ when the set is empty, where `> ALL` is **true** and `> (SELECT max(...))` is
null. Empty sets are where these operators stop agreeing with intuition, and it is worth checking
which behaviour you want rather than discovering it.

## What about speed

You will be told `IN` is slow, or that `EXISTS` is faster, or the reverse. Both claims were true of
some engine in some year. In PostgreSQL today, `IN`, `EXISTS` and the anti-join usually produce the
same plan, because the planner rewrites them into the same semi-join or anti-join. MySQL was
genuinely bad at `IN (subquery)` before version 8 and is not now.

So the rule for this course: **choose by correctness and by what reads clearly, and measure the
rest.** Lesson 10 is where measuring happens, and it is the only place a speed claim belongs.
