---
title: Migrations as code, and the checklist
version: 1
---

Every change in this lesson was typed into psql, which is how you learn what each one does and is
not how a team should apply them. In a system that is changed often, **a schema change is code**:
written in a file, reviewed like any other diff, applied by a tool in the same order everywhere, and
recorded in the database so that it is never applied twice.

## What a migration tool gives you

Tools differ in language and details, Flyway, Liquibase, Alembic, Rails migrations, golang-migrate
and many more, and they share a model:

- **migrations are numbered files**, applied in order, each once;
- **the database records which have run**, in a table of its own, so the tool knows where each
  environment is;
- **migrations run before or with the deploy**, by the pipeline rather than by a person, so the
  schema and the code arrive together, in the order section 07 requires;
- **they go forward.** A "down" migration that undoes a change is useful in development and
  dangerous in production, where undoing a drop of a column does not bring its data back. In
  production a mistake is fixed by a new migration.

## The checklist

What this lesson measured reduces to a list a reviewer can hold a migration against:

1. **Does it take `ACCESS EXCLUSIVE`?** Then it runs with a short `lock_timeout` and is retried,
   never left to wait (sections 03 and 04).
2. **Does it rewrite or scan the table while locked?** Then it is redone another way: a constant
   default, an index built `CONCURRENTLY`, a constraint added `NOT VALID` and validated (sections 05,
   06 and 09).
3. **Does it break a running version of the program?** Then it is split into expand and contract,
   across deploys (section 07).
4. **Does it change many rows?** Then it is a batched backfill, resumable, watched on the replicas
   (section 08).
5. **Has it been timed on a copy of production, at production's size?** Two milliseconds on a
   development database says nothing about two hundred million rows.

The last one is the one teams skip, and it is the one that would have caught everything else on
the list.
