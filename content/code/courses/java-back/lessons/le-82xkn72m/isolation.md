---
title: Isolation, and the level PostgreSQL gives you
version: 1
---

The I in ACID is the letter that costs something. **Isolation decides what a transaction sees of the
others running at the same moment.** Complete isolation, every transaction behaving as if it were
alone, would mean running them one after another, and a shop that serves one customer at a time is
not a shop. So databases offer levels, and each level allows some interference in exchange for
running more at once.

The SQL standard defines four levels by the anomalies each one forbids:

| level | dirty read | non-repeatable read | phantom |
|---|---|---|---|
| `READ UNCOMMITTED` | possible | possible | possible |
| `READ COMMITTED` | prevented | possible | possible |
| `REPEATABLE READ` | prevented | prevented | possible |
| `SERIALIZABLE` | prevented | prevented | prevented |

A **dirty read** is seeing another transaction's change before it commits, a change that may still be
rolled back. A **non-repeatable read** is reading one row twice in a transaction and getting two
values, because somebody committed in between. A **phantom** is running one query twice and getting a
different set of rows.

## The level the bookshop runs at

The bookshop never chose a level, so it runs at PostgreSQL's default, `READ COMMITTED`. The database
says so when asked over the same connection the application uses:

```
MISSING CAPTURE isolation
```

`max_connections` is the other number in that output, and section 07 comes back to it.

At `READ COMMITTED`, **each statement sees what had been committed when that statement began**. Two
statements in one transaction can see two different states of the database, which is the
non-repeatable read the table allows. PostgreSQL accepts `READ UNCOMMITTED` and treats it as
`READ COMMITTED`, so a dirty read cannot happen there at all.

## Asking for a stricter level

`@Transactional` takes a level, as in `@Transactional(isolation = Isolation.REPEATABLE_READ)`. At
`REPEATABLE READ` PostgreSQL gives the whole transaction one snapshot, taken at its first statement.
The price shows up when two transactions update the same row: the second one does not wait and carry
on, it fails. Here the first `psql` command opens a `REPEATABLE READ` transaction, reads Persuasion's
stock and sleeps for two seconds; meanwhile the second, at the default level, takes a copy and commits.
When the first one wakes and tries to take a copy too, PostgreSQL refuses:

```
MISSING CAPTURE rr
```

The second transaction committed and the first was refused, so the stock went from 5 to 4 once.
Nothing was lost, and the refused transaction has to be run again from the start, by code somebody has
to write. That is why most applications stay at `READ COMMITTED` and lock the few rows that need it,
which is what section 06 does. `sql-databases` lesson 8 takes the levels, the anomalies and
`SERIALIZABLE` much further.

## The anomaly the table leaves out

The table has no column for the failure an order is exposed to. A **lost update** is two transactions
reading the same value, each computing a new value from it, and each writing its result, so that the
second write replaces the first without anybody noticing. It is possible at `READ COMMITTED`, and the
next section produces one on purpose.
