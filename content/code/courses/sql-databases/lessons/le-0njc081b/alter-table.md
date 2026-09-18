---
title: ALTER TABLE, and what it costs
version: 1
---

Creating a table is easy because nothing depends on it yet. Changing one is the job.

```sql
ALTER TABLE invoices ADD COLUMN notes text;
ALTER TABLE invoices DROP COLUMN notes;
ALTER TABLE invoices RENAME COLUMN notes TO remarks;
ALTER TABLE invoices ALTER COLUMN total TYPE numeric(14,2);
ALTER TABLE invoices ALTER COLUMN status SET NOT NULL;
ALTER TABLE invoices ADD CONSTRAINT invoices_total_not_negative CHECK (total >= 0);
```

Every one of those is one line. They are not one cost.

## Three speeds, and knowing which is which is the skill

**Instant — catalogue only.** The table is not read, no rows move, and it finishes in milliseconds
whether the table holds ten rows or ten billion:

- `ADD COLUMN` with no default, or with a constant default (since PostgreSQL 11)
- `DROP COLUMN` — the data is not removed, the column is marked gone and the space is recovered
  later by vacuum
- `RENAME` anything
- `SET DEFAULT`, `DROP DEFAULT`
- widening a `varchar(n)` to a larger `n`, or to `text`

**A full scan — every row is read, nothing is rewritten.** Proportional to the table:

- `ADD CONSTRAINT … CHECK` — every existing row must satisfy it
- `SET NOT NULL` — every existing row must be non-null
- `ADD FOREIGN KEY` — every existing value must exist on the other side

**A full rewrite — every row is written again**, and the table needs roughly twice its size in
free disk while it happens:

- `ALTER COLUMN … TYPE` in most cases, including `integer` to `bigint`
- `ADD COLUMN` with a **volatile** default, such as `DEFAULT gen_random_uuid()`, because each row
  needs a different value

## The lock is the thing that matters

Speed is not really the question. **`ALTER TABLE` takes an `ACCESS EXCLUSIVE` lock**, which blocks
everything — every read, every write, from everybody — for as long as it runs.

On a small table that is a few milliseconds and nobody notices. On a hundred-million-row table a
rewrite is minutes, and for those minutes **the application is down**, not slow.

And there is a worse failure, which is the one that actually causes outages:

> **`ALTER TABLE` waits for the lock, and everything arriving behind it waits too.**

One long-running `SELECT` is enough. Your `ALTER` queues behind it, and every query that arrives
afterwards queues behind your `ALTER` — including the fast ones that would have been fine. A
statement that would have taken two milliseconds takes the site offline because it was patient.

The mitigation is to refuse to wait:

```sql
SET lock_timeout = '3s';
ALTER TABLE invoices ADD COLUMN notes text;
```

Now it either gets the lock quickly or gives up, and giving up is the outcome you want. You try
again when the long query has finished, and nothing queued behind you in the meantime.

## `ADD COLUMN` with a default is no longer what it was

This is worth knowing because the old advice is still repeated everywhere.

Before PostgreSQL 11, `ADD COLUMN … DEFAULT 'x'` rewrote the entire table, so the standard advice
was: add it nullable, backfill in batches, then set the default. **Since 11, a constant default is
stored in the catalogue and existing rows are told about it as they are read** — so it is instant.

A **volatile** default still rewrites, because every row genuinely needs its own value. That is the
line: `DEFAULT 'draft'` is instant, `DEFAULT gen_random_uuid()` is a rewrite.

## Dropping, and what goes with it

```sql
DROP TABLE invoices;                    -- refused if anything references it
DROP TABLE invoices CASCADE;            -- drops the referencing constraints too
```

`CASCADE` here does **not** delete rows in other tables. It drops the *constraints* that point at
this table, silently leaving those tables with columns that reference nothing. That is worse than
it sounds: the data survives, the rule does not, and nobody is told.

And the two ways to empty a table are not interchangeable:

| | |
|---|---|
| `DELETE FROM invoices` | row by row, fires triggers, can be rolled back, leaves dead rows for vacuum |
| `TRUNCATE invoices` | resets the table, very fast whatever the size, fires no row triggers, still transactional in PostgreSQL |

`TRUNCATE` being transactional is PostgreSQL-specific and genuinely useful — you can `BEGIN`,
truncate, load, and `COMMIT`, and readers see the old contents until the commit. In MySQL it
commits implicitly and there is no way back.

## The rule for a live system

> **Before running any `ALTER TABLE` on a table that matters, know which of the three speeds it is,
> and set a `lock_timeout`.**

Which change is which is not something to reason out under pressure — it is a table you look up,
and it is the one above. The next section is what to do when the change you need is in the third
category and the table is too big to stop.
