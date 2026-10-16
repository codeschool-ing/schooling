---
title: What always breaks
version: 1
---

A migration between engines looks like a copy: read the rows out of one server, write them into
the other. **The rows are the easy part.** What breaks is everything the two engines mean
differently by the same words, and a migration that copies every row can still change what half of
them say.

The list is short and it is the same on every migration, which is why it is worth learning before
the first one. Each item below is a difference in meaning, and each one survives a copy that
reports no errors at all.

## Names

**Every engine decides what an unquoted name means, and they disagree.** PostgreSQL folds an
unquoted identifier to lower case, so `Customers` and `customers` are one table. Oracle folds it to
UPPER case. SQL Server keeps the case you wrote and compares names by the database's collation,
which is usually case-insensitive. MySQL keeps the case too; on Linux a table name is a file name
and is case-sensitive, while a column name is not.

So a MySQL table called `Customers` with a column `CustomerID` has two possible futures in
PostgreSQL. Folded to `customers.customerid`, every query that never quoted the name keeps
working. Kept as `"Customers"."CustomerID"`, the case survives and **every query anybody ever
writes against it needs the double quotes**, forever.

## Nothing, and the empty string

**Oracle stores an empty string as NULL.** `INSERT INTO t (name) VALUES ('')` puts a NULL there, and
`WHERE name = ''` finds nothing. Every other engine in this course keeps the two apart. An Oracle
application has therefore been written by people who never had to tell them apart, and after the
migration its `WHERE name IS NULL` stops finding the rows that were empty strings everywhere else.

## Dates that do not exist

**MySQL can store `0000-00-00`**, a date with no year, month or day, and older applications used it
to mean "not known yet". PostgreSQL has no such date. Each one has to become something: NULL is the
honest answer, and it means a column declared `NOT NULL` in MySQL cannot stay `NOT NULL`.

Dates also disagree about time. An Oracle `DATE` carries a time of day to the second. A MySQL
`DATETIME` and a SQL Server `datetime` carry no time zone, so the migration has to decide which zone
they were written in. SQL Server's old `datetime` also rounds to steps of about three milliseconds,
so a value that was never exact arrives exact in PostgreSQL.

## Numbers

**PostgreSQL has no unsigned integers.** A MySQL `INT UNSIGNED` holds up to 4,294,967,295, which is
twice what a PostgreSQL `integer` can, so it becomes `bigint`. A `BIGINT UNSIGNED` has nowhere to go
but `numeric(20)`. Oracle's `NUMBER` has no fixed size at all, and choosing between `integer`,
`bigint` and `numeric` for each column is a decision about every value already in it.

## Numbering rows

**`AUTO_INCREMENT`, SQL Server's `IDENTITY(1,1)` and Oracle's sequences all become a PostgreSQL
sequence**, usually behind an identity column. The rows arrive with the numbers they already had,
and the sequence has to start after the highest of them. A sequence left at 1 makes the first new
row collide with row 1, on the morning the application goes live.

## Comparing text

**The collation decides whether `'abc' = 'ABC'`.** MySQL 8's default, `utf8mb4_0900_ai_ci`, is
accent-insensitive (`ai`) and case-insensitive (`ci`), and so is a typical SQL Server install.
PostgreSQL's default compares exactly. The same `WHERE email = 'ANA@EXAMPLE.COM'` finds the row in
one engine and not in the other, and a `UNIQUE` key that refused `Ana@` beside `ana@` in MySQL
accepts both in PostgreSQL.

The character set breaks in its own way. MySQL's old `utf8` is three bytes per character at most
and cannot hold an emoji; `utf8mb4` is the real UTF-8. Text written by a client that announced
`latin1` while sending UTF-8 is stored wrong already, and arrives wrong in perfect order.

## Booleans

**MySQL has no boolean type.** `BOOLEAN` is a synonym for `TINYINT(1)`, and the column holds any
number from -128 to 127, so a flag column can contain 2. SQL Server uses `bit`. Oracle had no
boolean column at all until 23ai, and older schemas use `NUMBER(1)` or `CHAR(1)` holding `'Y'` and
`'N'`. A migration that turns all of these into `boolean` is a good decision and a lossy one.

## The tools, and what none of them moves

| from | the usual tool | notes |
| --- | --- | --- |
| MySQL, SQL Server, SQLite | pgloader | open source, run in this lesson |
| Oracle | ora2pg | open source, reads the schema, the data and PL/SQL |
| any of them, into a cloud | the provider's own service | AWS DMS with its Schema Conversion Tool, for one |

Oracle and SQL Server are not installed in this course, and nothing in this lesson ran against them.
MySQL is, and the rest of the lesson migrates a small MySQL database for real.

Every one of those tools moves the schema and the rows. **None of them moves the application.**
Its SQL was written in the source engine's dialect, and the last section of this lesson is about
what that costs.
