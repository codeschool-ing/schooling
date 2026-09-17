---
title: Choosing columns, and the habit to break early
version: 1
---

```sql
SELECT name, price FROM products;
```

The `SELECT` list is what comes back. It can hold columns, expressions, literals and functions, and
each entry can be given a name.

```sql
SELECT name,
       price,
       price * 1.23        AS gross,
       upper(sku)          AS code,
       'EUR'               AS currency,
       now()               AS as_of
FROM   products;
```

`AS` is optional — `price * 1.23 gross` works — and writing it makes the list readable, especially
when somebody scans down a long one looking for where an alias came from.

**Without a name, an expression gets whatever the database decides.** `price * 1.23` comes back as
`?column?`, which every client displays and no program can rely on. Name anything that is not a
plain column.

## `SELECT *` is for the terminal

```sql
SELECT * FROM products;
```

It is the right thing to type when you are exploring a table you have never seen. It is a habit
worth breaking everywhere else, for four reasons that all have the same shape — **you get whatever
the table happens to have today**:

**A new column changes your result silently.** Somebody adds `internal_notes` to `products`, and
your report grows a column, your CSV export gains a field, and your application's row parser
receives something it was not expecting.

**It fetches columns nobody reads.** A `text` column holding a description is transferred across
the network on every row of every query that did not need it. On a wide table this is most of the
cost of the query.

**It prevents an index-only scan.** Lesson 9's subject, and worth the forward reference: if a query
asks only for columns that are in an index, the database can answer from the index without touching
the table at all. Asking for `*` guarantees it cannot.

**It hides what a query depends on.** `SELECT *` does not tell a reader — or a program searching
the codebase — which columns actually matter. When somebody proposes dropping a column, nothing
finds the queries that would break.

> Name the columns. It is barely more typing, and every one of the four failures above is a thing
> you would otherwise find out about later, from a user.

## Duplicate names, and why qualifying is worth the habit

Two tables can both have `id` and `name`. When lesson 5 joins them, the result has two of each, and
which one you get is not something to leave to chance:

```sql
SELECT p.name AS product, c.name AS category
FROM   products p
JOIN   categories c ON c.id = p.category_id;
```

The short alias — `products p` — is standard and worth using as soon as there is more than one
table. Qualify every column even when it is unambiguous today, because a column added to the other
table tomorrow can make it ambiguous, and a query that was correct becomes an error or, worse,
silently reads the wrong one.

## Expressions, and where they belong

Anything you can compute can go in the list:

```sql
SELECT name,
       round(price * 1.23, 2)                     AS gross,
       coalesce(description, 'No description')    AS description,
       price > 100                                AS is_expensive,
       extract(year FROM created_at)              AS created_year
FROM   products;
```

Two habits worth forming now.

**`round(x, 2)` for money on the way out, not in the column.** The stored value is `numeric` and
exact; rounding is a presentation decision, and doing it once at the end is different from doing it
at every intermediate step, which is how totals stop adding up.

**`coalesce(a, b)` returns the first argument that is not null.** It is the standard way to give a
missing value a display form — and it is a display decision. Writing `coalesce(price, 0)` in the
middle of a calculation is a claim that an unknown price is free, which is exactly the lesson-1
mistake of treating `NULL` as zero.

## Literals and the empty `FROM`

PostgreSQL will evaluate an expression with no table at all, which is how you try things:

```sql
SELECT 1 + 1;
SELECT now();
SELECT 'ana@Example.com' = lower('ana@Example.com');
```

That third line is how you check the case question from lesson 3 in two seconds rather than by
reasoning about it. Most of what this course teaches can be confirmed that way, and confirming is
always better than remembering.
