---
title: The file that runs on every start
version: 1
---

Since lesson 9 the bookshop's tables have come from `schema.sql` and its rows from `data.sql`, and
`spring.sql.init.mode=always` tells Spring Boot to run both **on every start**. Every statement in them
therefore has to be harmless the second time. That is why lesson 10 wrote `CREATE TABLE IF NOT EXISTS`
and ended each `INSERT` with `ON CONFLICT ... DO NOTHING`: without those guards, the second start would
fail on a table that already exists or a name that is already there.

The picture most people hold is that `schema.sql` describes the schema, so changing the file changes the
schema. **It describes the schema of an empty database, and of no other.** A real change shows it.
Suppose the shop wants a stock count on every book. Open `src/main/resources/schema.sql` and add a
column to `book`, so that the file reads:

```sql
CREATE TABLE IF NOT EXISTS author (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author_id   bigint    NOT NULL REFERENCES author (id),
    price_cents integer   NOT NULL CHECK (price_cents >= 0),
    stock       integer   NOT NULL DEFAULT 0
);
```

Build, start the application in your second terminal as in the lessons before, and ask PostgreSQL what
the table looks like. `psql` accepts the whole connection as one URL; the password is in it only because
it is this course's development password:

```
@@schemasql@@
```

The application started without a word of complaint, and the table has no `stock` column. `IF NOT
EXISTS` found a table called `book`, and skipped the whole statement, new column included. Nothing
failed, so nothing said so: the file now describes a table that does not exist anywhere except in a
brand-new database.

The guard is not the problem; any version of this file has the same three gaps.

- **It cannot change what exists.** An `ALTER TABLE book ADD COLUMN stock ...` would work once and fail
  on every start after it, so each change would need its own guard, written by hand, forever.
- **It keeps no record.** The database has no idea which version of the file it last saw, so neither do
  you.
- **Every copy of the database drifts on its own.** Your laptop, a colleague's and the production
  server each started from a different version of the file, and nothing can tell you which.

What a schema needs instead is **a sequence of changes**, each applied once, in order, with the
database itself recording which ones it has received. That is a **migration tool**, and Spring Boot
supports two: **Flyway**, which the bookshop uses from here on, and **Liquibase**, which the last
section of this lesson runs for comparison. The `stock` column is lesson 14's, which adds it properly;
the edit you just made disappears in the next section, with the file it was made in.
