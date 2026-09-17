---
title: NULL, now that you are writing queries
version: 1
---

Lesson 1 said what `NULL` is: not zero, not empty, **unknown** — and that comparing anything with
an unknown gives unknown. This section is what that does to the queries you are now writing.

## The rule that produces every surprise below

> **`WHERE` keeps a row when the condition is true. Unknown is not true.**

That is it. Everything else follows.

## Rows that are in neither half

Ten products, three with no category:

```sql
SELECT count(*) FROM products WHERE category = 'kitchen';     -- 4
SELECT count(*) FROM products WHERE category <> 'kitchen';    -- 3
```

Four and three is seven, and there are ten. The three unknowns are in **neither** answer, and
nothing told you.

This is the shape of the bug in the wild: a report of "products outside the kitchen category"
quietly omits everything uncategorised, the number is a bit low, and it stays a bit low for years
because it is plausible.

To include them, say so:

```sql
SELECT count(*) FROM products WHERE category <> 'kitchen' OR category IS NULL;   -- 6
```

## `= NULL` is not an error, which is worse

```sql
SELECT count(*) FROM products WHERE category = NULL;      -- 0, always
SELECT count(*) FROM products WHERE category IS NULL;     -- 3
```

The first is valid SQL that is never true. No error, no warning, and an answer of zero that looks
like a real finding. `IS NULL` and `IS NOT NULL` ask about the state rather than comparing values,
and they are the only way.

## `NOT IN` with a null returns nothing at all

The nastiest of them, and it is worth writing out:

```sql
SELECT * FROM products WHERE category_id NOT IN (1, 2, NULL);
```

Zero rows. Always, whatever the table holds. `x NOT IN (1, 2, NULL)` unfolds to `x <> 1 AND x <> 2
AND x <> NULL`, and that last term is unknown, so the whole `AND` can never be true.

It is rare to write a literal `NULL` in a list. It is **not** rare for a subquery to return one:

```sql
SELECT * FROM products
WHERE  category_id NOT IN (SELECT id FROM categories WHERE archived);
```

One archived category with a null `id` — or, more commonly, a subquery over a nullable column — and
this returns nothing. The query is correct SQL, the answer is empty, and nobody is told.

**Use `NOT EXISTS` instead**, which is lesson 7's subject and is immune to this:

```sql
SELECT * FROM products p
WHERE  NOT EXISTS (SELECT 1 FROM categories c WHERE c.id = p.category_id AND c.archived);
```

## `NOT` does not flip unknown

```sql
WHERE NOT (price > 100)
```

If `price` is null, `price > 100` is unknown, and `NOT unknown` is **still unknown** — so the row is
dropped by this condition exactly as it was dropped by the original one. Negating a condition does
not give you the rows it excluded; it gives you the rows where it was definitely false.

The three-valued truth table, once, because it explains all of the above:

| | AND | OR |
|---|---|---|
| **true, unknown** | unknown | **true** |
| **false, unknown** | **false** | unknown |
| **unknown, unknown** | unknown | unknown |

Two of those are worth noticing: `true OR unknown` is **true**, and `false AND unknown` is
**false**. The unknown does not always spread — when the other operand already settles the
question, the answer is known.

## The tools

```sql
coalesce(price, 0)                  -- the first argument that is not null
nullif(status, '')                  -- NULL when the two are equal, else the first
price IS DISTINCT FROM 20           -- like <>, but treats NULL as a comparable value
```

**`IS DISTINCT FROM` is the one people do not know about and often want.** Ordinary `<>` says
unknown when either side is null; `IS DISTINCT FROM` answers true or false, treating null as just
another value that is different from 20. When you want "everything that is not 20, including the
ones we do not know about", it is one operator instead of an `OR`.

**And `coalesce` in a `WHERE` clause deserves suspicion.** `WHERE coalesce(price, 0) > 100` reads
well and does two things at once: it makes a claim that an unknown price is zero, and — from the
`where` section — it puts a function around the column and loses the index. Usually what was meant
is `WHERE price > 100`, which already excludes the unknowns, or `WHERE price > 100 OR price IS
NULL` if they belong in the answer. Deciding which is the point.

## The habit

Every time you write a condition on a nullable column, ask one question:

> **What should happen to the rows where this is unknown?**

There are three honest answers — keep them, drop them, or the column should never have been
nullable. Lesson 1's advice was the last one, applied at design time. This is what you do about the
columns where it was not.
