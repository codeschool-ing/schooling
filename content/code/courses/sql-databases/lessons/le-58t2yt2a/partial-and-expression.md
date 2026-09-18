---
title: Two kinds that repay the trouble
version: 1
---

These two solve problems the ordinary index cannot, they are cheap, and most people have never
written one. If you take two things from this lesson, take these.

## A partial index covers some of the rows

```sql
CREATE INDEX ON jobs (created_at) WHERE status = 'pending';
```

The `WHERE` is part of the index, not part of a query. Only the pending rows get an entry.

On a jobs table with fifty million finished rows and four hundred pending ones, that index is four
hundred entries. It fits in memory, the lookup is instant, and — the part people miss — **the
inserts and updates of the other fifty million rows do not touch it at all.** A row only enters the
index when it becomes pending and leaves when it stops being, so the write cost is proportional to
the rows you care about rather than to the table.

It answers the objection from two sections ago. An ordinary index on a status column with three
values earns nothing, because no value is selective enough. A partial index on the rare value is
selective by construction.

The shapes worth recognising:

```sql
-- the small live subset of a big archive
CREATE INDEX ON orders (customer_id) WHERE NOT archived;

-- rows with a value, on a mostly-null column
CREATE INDEX ON users (deleted_at) WHERE deleted_at IS NOT NULL;

-- uniqueness that applies to some rows only
CREATE UNIQUE INDEX ON users (email) WHERE deleted_at IS NULL;
```

That last one is worth stopping on. *"An email must be unique among the users who are not deleted"*
cannot be said with an ordinary `UNIQUE` constraint, and people end up enforcing it in application
code — which lesson 8 showed is a write skew waiting for two requests to arrive together. A partial
unique index enforces it properly, at every isolation level, against every connection.

**The planner has to prove the index applies.** A query saying `WHERE status = 'pending'` can use
the index above; one saying `WHERE status = $1` cannot, because the value is not known when the
plan is made, and one saying `WHERE status <> 'done'` cannot either, because that is not the same
condition. Keep the query's condition recognisably the same as the index's.

MySQL and MariaDB have no partial indexes. PostgreSQL and SQLite do.

## An expression index covers a computed value

The section on unused indexes said a function around a column defeats the index. This is the other
way to fix it: index the function.

```sql
CREATE INDEX ON customers (lower(email));

SELECT * FROM customers WHERE lower(email) = 'ana@example.com';   -- uses it
```

The index stores the lowercased values, sorted. The query's expression matches the index's
expression, so it applies.

Two rules govern it, and both catch people:

**The query has to spell the expression the same way.** `lower(email)` in the index and
`lower(trim(email))` in the query are two different expressions, and the index is not used. This is
the commonest reason an expression index looks broken.

**The expression has to be immutable.** The same input must always give the same output, for ever —
otherwise the index would be a record of an answer that has since changed. So `lower(x)` is fine
and `now()` is not, and the one that catches people is a timestamp conversion that depends on the
session's time zone. PostgreSQL refuses those, and the error is telling you something true about
your data rather than being awkward.

Useful shapes:

```sql
CREATE INDEX ON customers (lower(email));                        -- case-insensitive lookup
CREATE INDEX ON orders (date_trunc('month', placed_at));         -- lesson 6's monthly grouping
CREATE INDEX ON documents ((payload ->> 'customer_id'));         -- a field inside a JSON column
```

The last one is how a JSON column becomes searchable without being taken apart into real columns —
which is worth knowing, and is not an argument for putting things in JSON that belong in columns.

MySQL 8 has functional indexes, and MariaDB and older MySQL versions get the same effect with a
generated column plus an index on it. SQLite has expression indexes.

## Combine them

Nothing stops you:

```sql
CREATE UNIQUE INDEX ON users (lower(email)) WHERE deleted_at IS NULL;
```

*"No two active users may have the same email, whatever case they typed it in."* One line, enforced
by the database, immune to concurrency, and the alternative is a paragraph of application code that
is wrong in a way nobody notices until two people sign up in the same second.
