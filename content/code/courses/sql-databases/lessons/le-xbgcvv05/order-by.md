---
title: ORDER BY, and the arrangement nobody promised you
version: 2
---

Rows have no order. Lesson 1 said it as a property of a table; here is what it means for a query.

> **Without `ORDER BY`, the order rows come back in is not defined and may change.**

Not "usually insertion order". Not "usually by key". Undefined — and in practice it changes when
the table grows, when an index is added, when the planner picks a different route, or when
PostgreSQL is upgraded. A query that produced a stable order for a year can start producing another
one after a change nobody connected to it.

```sql
SELECT name, price FROM products ORDER BY price;
```

## Direction, and several keys

```sql
ORDER BY price DESC
ORDER BY category, price DESC        -- category ascending, then price descending within it
ORDER BY 2                           -- by the second column of the SELECT list
```

`ASC` is the default and writing it is optional. **Each key has its own direction** — `ORDER BY a,
b DESC` sorts `a` ascending and `b` descending, which catches people who expect `DESC` to apply to
both.

`ORDER BY 2` works and is worth avoiding: it points at a position in the `SELECT` list, so
inserting a column silently re-sorts by something else. It is the same positional fragility this
course keeps refusing.

## Where nulls go

```sql
ORDER BY price;                       -- nulls last, in PostgreSQL, ascending
ORDER BY price DESC;                  -- nulls first
ORDER BY price NULLS FIRST;           -- say it and stop guessing
```

PostgreSQL treats null as larger than everything, so it lands last ascending and first descending.
**Other databases choose differently** — MySQL sorts nulls first ascending — so a query that puts
the empty ones at the bottom on one database puts them at the top on another.

Say `NULLS FIRST` or `NULLS LAST` whenever the column is nullable and the position matters. It is
four characters and it removes a difference nobody tests for.

## Sorting by something you computed

```sql
SELECT name, price * 1.23 AS gross FROM products ORDER BY gross DESC;
SELECT name FROM products ORDER BY length(name);
SELECT name, price FROM products ORDER BY (price > 100) DESC, name;
```

All three work. `ORDER BY` runs after `SELECT`, so the alias exists; and it may sort by an
expression that is not in the output at all, which is how the second one works.

That third line is a useful trick: a boolean sorts false before true, so `DESC` puts the expensive
ones first and then sorts the rest by name. It is how you say "these first, then everything else"
without two queries.

## Text sorts by its collation

```sql
SELECT name FROM people ORDER BY name;
SELECT name FROM people ORDER BY name COLLATE "C";
```

From lesson 3: under a Portuguese collation `Álvaro` sorts among the As; under `C`, which is byte
order, it sorts after `Z`. Neither is wrong and they are different answers, so the one that must
not vary between machines should say which it wants.

## The sort that does not settle ties

This is the one that produces a real bug, and it is the bridge to the next section:

```sql
SELECT name FROM products ORDER BY category LIMIT 10;
```

Twenty products in the `kitchen` category, and you asked for ten. **Which ten is undefined**,
because `ORDER BY category` says nothing about how rows with the same category are arranged among
themselves. Run it twice and you can get two different sets.

The fix is to make the sort total by ending with something unique:

```sql
SELECT name FROM products ORDER BY category, id LIMIT 10;
```

> **Any query with `LIMIT` needs an `ORDER BY` that cannot tie.** Ending on the primary key is the
> cheapest way to guarantee it.

Without that, paging shows a row twice and skips another, the numbers in a report shift between
refreshes, and every one of those is intermittent and impossible to reproduce on a small table.

## It costs something

Sorting is real work: the database gathers the rows, sorts them in memory, and spills to disk if
there are too many. **An index can remove that cost entirely** — an index is already a sorted
structure, so `ORDER BY price` over an index on `price` can be answered by walking it.

That is lesson 9, and the thing to carry now is that `ORDER BY` on a column with an index and
`ORDER BY` on an expression are not the same price, in the same way that `LIKE 'a%'` and
`LIKE '%a%'` are not.
