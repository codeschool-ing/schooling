---
title: A schema changes, and the change has to travel
version: 1
---

boxoffice's table was made in lesson 6 by running `schema.sql` once with `psql`, and that file cannot be
run twice: the second time, `CREATE TABLE` fails because the table exists. That was fine for one table on
one laptop. **This lesson adds a second table, `tickets`, and the question becomes how that change reaches
every database boxoffice runs against**: yours, a colleague's, the test database of lesson 15, and one
day a production database full of sales that must not be lost.

Running a new `CREATE TABLE` by hand on each one does not scale past the first time somebody forgets.
Nothing records which changes a given database has had, so nobody can tell whether the production
database is behind the code that is about to be deployed against it.

## A migration is a numbered change

The answer every ecosystem has converged on is the same. **Each change to the schema is a small file with
a number**, kept in the repository beside the code that needs it. A tool keeps a table inside each database
listing the numbers that database has already received, and applying migrations means running, in order,
every file whose number is not in that table yet.

That gives three properties at once:

- **every database can say where it is**, by reading its own table;
- **the same files bring any database to the same place**, whether it is empty or one change behind;
- **the history is in version control**, reviewed like code, with the change and the code that needs it
  in the same commit.

Most migration tools also let each file say how to undo itself, a **down** migration. It is useful in
development, to step back and try again. In production it is rarely the way out of a bad change, because
a down that drops a column also drops the data written into it since; **the usual fix for a bad migration
is a new migration that corrects it**.

## Two tools, one idea

Go has two widely used migration tools, and they differ in shape more than in substance:

| | golang-migrate | goose |
|---|---|---|
| a migration is | two files, `NNN_name.up.sql` and `NNN_name.down.sql` | one file, with `-- +goose Up` and `-- +goose Down` sections |
| written in | SQL | SQL, or Go for a change SQL cannot express |
| used from | a command-line tool, or a library | a command-line tool, or a library |

boxoffice uses **goose**: one file per change reads more easily, and the library can run migrations
compiled into the binary, which section 04 does. sqlc understands both formats, so the migration files can
also be the schema sqlc reads.
