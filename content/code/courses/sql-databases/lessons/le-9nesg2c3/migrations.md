---
title: The schema as a sequence of changes
version: 1
---

Lesson 3 changed tables at a prompt. A real system cannot: the schema has to be the same on every
developer's machine, on staging and on production, and it has to change in step with the code that
uses it. A **migration** is one change to the schema, written as a file, versioned with the code,
and applied exactly once to each database.

```
migrations/
    0001_create_customers.sql
    0002_create_orders.sql
    0003_add_orders_status.sql
    0004_index_orders_customer_id.sql
```

Every migration tool — Django's, Rails', Flyway, Liquibase, Alembic, Prisma Migrate,
`golang-migrate` — is this folder plus one table. The table lives in the database itself and records which
migrations have run:

```
version | applied_at
--------+---------------------
   0001 | 2026-03-01 10:00:00
   0002 | 2026-03-01 10:00:00
   0003 | 2026-04-12 09:30:00
```

Run the tool and it applies every file the table does not yet list, in order, and records each one.
Run it again and it does nothing. That is the whole mechanism, and everything else is a
consequence of it.

## Each one runs once, so each one must be right

Lesson 3 said `CREATE TABLE IF NOT EXISTS` hides the fact that a script ran twice. Under
migrations a script cannot run twice, so the `IF NOT EXISTS` has nothing to hide and only removes a
check. A migration that finds its table already there has been run against a database that is not
in the state its version says, and that should fail loudly rather than pass.

Which leads to the rule that every team learns once by breaking it:

> **A migration that has been applied anywhere is never edited.** Fix it with the next one.

Edit `0003` after production ran it and there are now two databases that both say `0003` applied
and have different schemas. Nothing detects it, and the difference surfaces as a query that works
in one place and not the other. A new migration, `0005`, runs everywhere it has not run, which is
the guarantee the table gives and editing takes away.

## Up, down, and forward-only

Most tools let a migration carry its reverse — `up` adds the column, `down` drops it — so that a
bad deploy can be rolled back. Worth writing where it is cheap, and honest about where it is not:
`down` for a dropped column cannot bring the data back, and `down` for a migration that ran a
month ago is a migration nobody has tested against the rows that arrived since. In practice
production rolls **forward**: the fix for a bad migration is another migration, and `down` is for
a developer's machine.

## A migration is a transaction, except when it cannot be

Most tools run each migration inside a transaction, so that a migration that fails halfway leaves
the schema as it was. PostgreSQL can do that for DDL and MySQL mostly cannot, which is one of the
differences lesson 12 goes through — on MySQL a failed migration is half applied and has to be
repaired by hand.

And lesson 9's index build is the exception on both:

```
shop=# BEGIN;
BEGIN

shop=*# CREATE INDEX CONCURRENTLY ON orders (total);
ERROR:  CREATE INDEX CONCURRENTLY cannot run inside a transaction block
```

`CONCURRENTLY` refuses to run inside a transaction, so the migration that builds an index on a
live table has to be marked as one the tool must not wrap. Every tool has a way to say so —
Django's `atomic = False`, Rails' `disable_ddl_transaction!`, Alembic's autocommit block — and a
migration that does not say it fails at deploy time with the line above, which is the good
outcome. The bad one is a tool that silently drops `CONCURRENTLY` and takes the lock.

## The dangerous ones, and the tool that stops you

Lesson 3's list — adding a `NOT NULL` column to a big table, renaming, changing a type, adding a
constraint that scans — is where a migration takes a lock and holds it for minutes with lesson 3's
queue forming behind it. Tools have learnt this: `strong_migrations` for Rails, `squawk` for
anything emitting SQL, Django's checks, refuse or warn on exactly those operations and suggest the
safe shape.

The safe shape for a rename is the one the tool cannot write for you, because it spans three
deploys:

1. **Expand.** Add the new column. Write to both columns from the code. Backfill the old rows.
2. **Migrate the readers.** Change the code to read the new column.
3. **Contract.** Stop writing the old one; drop it.

Three migrations, three deploys, and at no point does a running version of the code name a column
that does not exist. A single `ALTER TABLE … RENAME` is one migration and one deploy, and between
the moment the column is renamed and the moment the new code is running, every request fails.
Which is lesson 3's point that a change to a live table is a change to the code that is currently
reading it.

## Schema migrations and data migrations

A migration that changes the shape — a column, an index, a constraint — is one kind. A migration
that changes the rows — backfilling the new column, splitting a name into two, fixing a status
that was spelt wrong — is another, and mixing them is the mistake.

A data migration on a large table is an `UPDATE` over millions of rows in one transaction, which
lesson 8 priced: locks held for the duration, and every row version kept until the end. It is
written in batches, it is written to be re-runnable, and it is written in the application's
language rather than in the migration tool, because it needs a loop and error handling and a way to
resume. Keep it out of the schema migration that a deploy runs synchronously, or the deploy is
the thing waiting on the millions of rows.

## What the tool does not know

It applies files in order and records that it did. It does not know whether the file is safe,
whether the `down` works, or whether a column it is about to drop is still read by the version of
the code that is running during the deploy. Those are lesson 3's questions, and the tool's warning
is the moment to answer them rather than the moment to add the flag that silences it.
