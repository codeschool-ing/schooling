---
title: The first restore, and how to know it worked
version: 1
---

A backup, a restore and a check that the restore is the database you had. All three, in that
order, before anything more sophisticated: the rest of the course adds speed, precision and
distance to this loop, and never removes a step from it.

## The copy

`pg_dump` connects to a database like any other client and writes out everything needed to build
it again: the tables, their rows, the indexes, the constraints. `-Fc` asks for PostgreSQL's
**custom format**, a compressed archive that only `pg_restore` reads; lesson 2 compares it with the
others.

```
ana@vm:~$ pg_dump -Fc shop > shop.dump
ana@vm:~$ ls -l shop.dump
-rw-r--r-- 1 ana ana 542201 Oct 10 03:23 shop.dump
ana@vm:~$ createdb shop_restored
ana@vm:~$ pg_restore -d shop_restored shop.dump
```

Half a megabyte for fifty-one thousand rows, and `pg_restore` printed nothing, which means it found
nothing to complain about. That is exactly as much evidence as a nightly job's green tick: **a
program ran and did not report an error.** Whether `shop_restored` is the shop is the next
question.

## What "the same database" means

Comparing two databases row by row is slow and, for a big one, impractical. What works is a
**report**: a handful of queries whose answers would change if anything were missing or different,
run against both copies, with the two outputs compared character by character.

Save this as `verify.sql`:

```schooling-example
{"language": "sql", "file": "verify.sql", "parts": [{"code": "-- verify.sql: a report that two copies of shop must print identically\nSELECT 'customers', count(*), max(id), sum(length(name || city))\nFROM customers;\nSELECT 'orders', count(*), max(id), sum(total_cents)\nFROM orders;", "note": "One line per table: how many rows, the highest id, and a sum over a column. A missing row changes the count; a damaged row changes the sum."}, {"code": "SELECT 'orders by city', c.city, count(*), sum(o.total_cents)\nFROM orders o JOIN customers c ON c.id = o.customer_id\nGROUP BY c.city ORDER BY c.city;", "note": "The join, because a restore can bring back both tables and lose the link between them."}, {"code": "SELECT 'indexes', string_agg(indexname, ' ' ORDER BY indexname)\nFROM pg_indexes WHERE schemaname = 'public';", "note": "And the indexes by name, which a restore can skip without losing a single row. Every query has an ORDER BY, or two identical databases could print their rows in different orders and fail the comparison."}]}
```

Run it against both, into two files, and let `diff` compare them:

```
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ psql -X -A -t shop_restored -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
ana@vm:~$ cat restored.txt
customers|1000|1000|19643
orders|50000|50000|524985000
orders by city|Belém|12500|131262500
orders by city|Curitiba|12500|131230000
orders by city|Porto Alegre|12500|131255000
orders by city|Recife|12500|131237500
indexes|customers_pkey orders_customer orders_pkey
```

`-A -t` asks `psql` for bare values separated by `|`, with no headers or padding, so the output is
only data. `-X` stops `psql` reading your personal settings, which would otherwise make the
report depend on who runs it. `diff` printed nothing and exited successfully, so `echo` ran.

**This is the first backup in this course that you know is good.** Not because a program exited
cleanly, but because you put the data back and it answered the same questions the same way.

## Making it fail, on purpose

A check you have never seen fail is a check you are trusting rather than using. Damage the copy by
one row and run the report again:

```
ana@vm:~$ psql shop_restored -c "DELETE FROM orders WHERE id = 49999"
DELETE 1
ana@vm:~$ psql -X -A -t shop_restored -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
2,3c2,3
< orders|50000|50000|524985000
< orders by city|Belém|12500|131262500
---
> orders|49999|50000|524979229
> orders by city|Belém|12499|131256729
```

One order out of fifty thousand, and the report says which numbers moved: the count, the sum, and
the city that customer lives in. The `max(id)` is unchanged, because the row deleted was not the
last one, and that is why the report asks more than one question per table.

Lesson 7 turns this into a drill with a stopwatch, against a separate server rather than a second
database on the same one, and lesson 7 is also where the report learns to describe a database
whose tables nobody listed in advance. For now, the loop is complete: **copy, restore, compare**.
