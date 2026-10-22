---
title: Three ways to the same table
version: 1
---

boxoffice has now talked to one table in three ways: pgx by hand in lesson 6, GORM in lesson 7's
`gormlab`, and sqlc in this lesson. All three can build the same service. **They differ in who writes the
SQL, who writes the Go that reads its results, and when a mistake is found.**

| | pgx by hand | GORM | sqlc |
|---|---|---|---|
| who writes the SQL | you | GORM, from your structs and calls | you |
| who writes the scan into Go | you | GORM, by reflection at run time | sqlc, as code you can read |
| where the SQL can be read | in the Go file | only in the log | in `queries.sql`, and copied into the generated file |
| a misspelled column is found | when the query runs | when the query runs | at `generate`, with a database to ask |
| a column and a field out of step | when the query runs | when the query runs | not possible: generated together |
| optional filters | build the string with care | natural | awkward, section 08 |
| the schema comes from | your SQL file | your structs, or your SQL | your SQL file |
| extra tools | none | none | sqlc, and gcc to build it |
| new modules | pgx | GORM, its driver, pgx | pgx |

**The middle column hides the SQL; the two outer columns keep it in front of you.** Between those two,
the difference is how much of the repetitive Go you write and how early a mistake surfaces: by hand, a
column added to the `SELECT` and forgotten in the `Scan` is a run-time error; with sqlc it cannot happen.

## And boxoffice

boxoffice keeps sqlc from here on. Its queries are few and fixed, its most important one is a carefully
written `UPDATE`, and the generated code removed the one class of mistake that hand-written scans invite,
at the price of one bug the conversion introduced and section 06 fixed. **That trade fits this service.**
A service with a search screen and fifty optional filters, or a team that thinks in models, would weigh it
differently, and section 08 of lesson 7 and section 08 of this one say where.

Lesson 9 builds on this code: the `DBTX` interface and `WithTx` of section 05 are exactly what a
transaction needs.
