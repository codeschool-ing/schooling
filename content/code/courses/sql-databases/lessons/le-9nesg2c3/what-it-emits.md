---
title: Every method call is a statement
version: 1
---

The application's code is the only thing the person who wrote it can see. The database sees
something else — the statements — and the two are not the same document. Before anything can be
fixed, the second document has to be read.

## Ask the ORM

Every mapper has a switch that prints the SQL it sends. Django's `connection.queries` and the
debug toolbar, Rails' development log, SQLAlchemy's `echo=True`, Hibernate's `show_sql`, Prisma's
query logging. Turn it on in development and leave it on: the moment it is off is the moment a
loop starts emitting fifty statements and nobody sees.

That switch is useful and it is not enough, for one reason: it shows what the ORM *thinks* it sent.
A connection pool that adds a `SET` on checkout, a driver that wraps the statement, a prepared
statement the ORM sent once and is now executing by name — those are between the ORM and the
server, and the ORM's log does not have them.

## Ask the database

The server sees exactly what arrived, and lesson 10's two tools apply unchanged. With
`log_min_duration_statement` at zero every statement is written to the log with its literals:

```
2026-09-17 23:32:44.738 UTC [5693] postgres@shop LOG:  duration: 0.845 ms  statement: SELECT id, name FROM customers ORDER BY id LIMIT 50;
2026-09-17 23:32:44.769 UTC [5695] postgres@shop LOG:  duration: 0.903 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 1;
2026-09-17 23:32:44.800 UTC [5697] postgres@shop LOG:  duration: 1.018 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 2;
2026-09-17 23:32:44.830 UTC [5699] postgres@shop LOG:  duration: 0.906 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 3;
```

That is a page of the shop, as the server received it: one query for fifty customers, and then a
query per customer, of which the log holds fifty and this shows three. Nothing in the application
code says fifty-one. The log does, and it says which values, in which order, from which process.

Zero is a development setting. On a busy server it writes a line per statement, which is the
disk filling up while you watch; set it, look, and put it back.

`pg_stat_statements` shows the same thing summarised, and it is the version to keep an eye on in
production:

```
shop=# SELECT calls, left(query, 60) AS query FROM pg_stat_statements WHERE query LIKE 'SELECT id,%' ORDER BY calls DESC;
 calls |                            query                             
-------+--------------------------------------------------------------
    50 | SELECT id, placed_at, total FROM orders WHERE customer_id = 
     1 | SELECT id, name FROM customers ORDER BY id LIMIT $1
(2 rows)
```

One row per distinct statement, and `calls` is the column that finds an N+1: **a query whose call
count is a multiple of another's is being run in a loop over that other's rows.** Fifty here,
against one. The next section is that number.

## The two questions to ask of any line

Reading the SQL an ORM emits is reading SQL, and everything lessons 4 to 10 taught applies. Two
questions are worth asking first, because they are where a mapper's output differs from what a
person would have written:

**Which columns did it ask for?** Almost every ORM selects every column of the table by default,
because it is building an object and the object has every field. Lesson 10 showed what that costs
when an index could have covered three of them, and the section on what the ORM hides has the
mechanism.

**How many times?** A statement is cheap once and expensive in a loop, and the loop is in the
application rather than in the statement. `calls` in `pg_stat_statements` is the only place the
count is visible without reading every line of the log.

## The rule

> **Know what it emitted.** Not what the documentation says the method does, and not what the
> code reads like — what arrived at the server, how many times, with which values.

Everything else in this lesson is a particular case of that sentence, and the tools for it are
the ones lesson 10 already gave you.
