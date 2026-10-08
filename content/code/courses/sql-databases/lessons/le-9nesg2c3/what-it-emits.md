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

The server sees exactly what arrived, and lesson 10's two tools apply unchanged. To have something
for them to see, this script plays an application rendering one page: fifty customers, then each
customer's orders, fetched the way the next section's four lines of ORM code fetch them. `psql`
stands in for the application, so every statement is its own short connection:

```sh
# page.sh: one page of fifty customers and their orders, a statement at a time.
psql -At shop -c "SELECT id, name FROM customers ORDER BY id LIMIT 50" |
while IFS='|' read -r id name; do
    psql -At shop -c "SELECT id, placed_at, total FROM orders WHERE customer_id = $id" >/dev/null
done
```

Save it as `page.sh` in the large shop from lesson 9, with the index lesson 10 built on
`customer_id`. Empty the statistics and turn the log up to everything: with
`log_min_duration_statement` at zero, every statement is written to it with its literals. Then
render the page once:

```
shop=# SELECT pg_stat_statements_reset();
 pg_stat_statements_reset 
--------------------------
 
(1 row)

shop=# ALTER SYSTEM SET log_min_duration_statement = 0;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

```
ana@vm:~$ sh page.sh
ana@vm:~$ sudo grep 'statement: SELECT id,' /var/log/postgresql/postgresql-16-main.log | tail -n 51 | head -n 4
2026-10-07 08:06:34.911 UTC [13999] ana@shop LOG:  duration: 1.360 ms  statement: SELECT id, name FROM customers ORDER BY id LIMIT 50
2026-10-07 08:06:34.944 UTC [14001] ana@shop LOG:  duration: 1.317 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 1
2026-10-07 08:06:34.977 UTC [14003] ana@shop LOG:  duration: 0.959 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 2
2026-10-07 08:06:35.011 UTC [14005] ana@shop LOG:  duration: 0.934 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 3
```

That is a page of the shop, as the server received it: one query for fifty customers, and then a
query per customer, of which the log holds fifty and this shows three. Nothing in the application
code says fifty-one. The log does, and it says which values, in which order, from which process.

Zero is a development setting. On a busy server it writes a line per statement, which is the
disk filling up while you watch; set it, look, and put it back:

```
shop=# ALTER SYSTEM RESET log_min_duration_statement;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

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
