---
title: Matching text, and what each way costs
version: 2
---

Exact equality was the last section. This one is the several ways to ask for "something like".

## `LIKE` and `ILIKE`

```sql
WHERE name LIKE 'Kettle%'      -- starts with
WHERE name LIKE '%kettle%'     -- contains
WHERE name LIKE '_ettle'       -- one character, then ettle
WHERE name ILIKE '%kettle%'    -- the same, ignoring case
```

Two wildcards and that is the whole language: `%` is any run of characters including none, `_` is
exactly one.

`ILIKE` is PostgreSQL's case-insensitive version and is not standard SQL. The portable spelling is
`WHERE lower(name) LIKE lower('%kettle%')`, which does the same thing and carries the function
problem from the last section.

**And there is a performance cliff between the first two**, which is worth knowing even before
lesson 9 explains why:

| | |
|---|---|
| `LIKE 'Kettle%'` | can use an ordinary index — it is a range of values that sort together |
| `LIKE '%kettle%'` | cannot. Every row must be examined |

A leading `%` means the match can start anywhere, and an index is sorted by the beginning of the
value, so there is nothing to look up. On a large table, a search box that generates
`LIKE '%…%'` is the query that eventually takes the site down.

PostgreSQL has answers — a trigram index, or full-text search — and they are lesson 9's and beyond.
The thing to carry now is that **the two patterns look almost identical and cost completely
different amounts.**

## Escaping, when the pattern contains a wildcard

To search for a literal `%` or `_`, say which character escapes:

```sql
WHERE code LIKE '100\%%' ESCAPE '\'    -- starts with the text 100%
```

This one matters most where it is least visible: a search box that passes user input straight into
a `LIKE` pattern. Somebody typing `%` matches everything, and somebody typing `_` matches any
character — so the search behaves strangely and nobody can reproduce it. The input has to be
escaped before it becomes a pattern.

## `IN`, and the list

```sql
WHERE category IN ('kitchen', 'garden', 'office')
```

Shorthand for three `OR`s, and clearer. It also takes a subquery, which is lesson 7:

```sql
WHERE category_id IN (SELECT id FROM categories WHERE active)
```

**`NOT IN` has the `NULL` problem from lesson 1**, and it is severe enough to repeat here: if the
list — or the subquery — contains a single `NULL`, `NOT IN` returns no rows at all, with no error.
The next section is about that.

## Regular expressions

When two wildcards are not enough:

```sql
WHERE sku ~ '^[A-Z]{3}-[0-9]{4}$'     -- matches
WHERE sku !~ '^[A-Z]{3}'              -- does not match
WHERE sku ~* 'kettle'                 -- matches, ignoring case
```

`~` is PostgreSQL's operator and the standard's is `SIMILAR TO`, which almost nobody uses. They are
powerful, they are not indexable in the general case, and they are the right tool for validating a
format rather than for searching a table.

**A better home for a format rule is a `CHECK` constraint**, from lesson 3: checking the shape of a
SKU once at write time is cheaper and stronger than filtering on it at read time, and it means the
bad value never entered.

## Which to reach for

| you want | use |
|---|---|
| exactly this value | `=` |
| one of a short list | `IN` |
| starts with | `LIKE 'x%'` — indexable |
| contains, small table | `ILIKE '%x%'` |
| contains, large table | a trigram index or full-text search — lesson 9 |
| a format rule | a regular expression, and better still a `CHECK` |

The one to be careful with is the fourth. It is the easiest to write, it works perfectly in
development where the table has two hundred rows, and it is the one that does not survive contact
with a real table.
