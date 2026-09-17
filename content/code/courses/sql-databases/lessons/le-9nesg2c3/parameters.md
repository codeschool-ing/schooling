---
title: The value travels separately from the statement
version: 1
---

Lesson 10 showed `pg_stat_statements` printing `WHERE email = $1`. That `$1` is not a display
convention. It is how the statement actually arrived: the text with a placeholder, and the value in
a separate part of the message. An ORM does this on every statement it emits, and it is the most
valuable thing it does.

## What a parameter is

```
shop=# PREPARE by_email (text) AS SELECT id, name FROM customers WHERE email = $1;
PREPARE

shop=# EXECUTE by_email('user42@example.com');
 id |      name      
----+----------------
 42 | Carla Oliveira
(1 row)

shop=# EXECUTE by_email('x'' OR ''1''=''1');
 id | name 
----+------
(0 rows)
```

`PREPARE` sends the statement once, with a placeholder; `EXECUTE` sends a value. The server parses
the statement when it is prepared and never again — the value cannot change its shape, because the
shape was fixed before the value arrived. The second `EXECUTE` sends a value that looks like SQL,
and it is compared against the `email` column as a string, matches no row, and does nothing else.

An ORM does the equivalent of this on every call, usually without a name — the driver sends the
statement and its values in one message, the server binds them, and the effect is the same. You
never write `PREPARE` yourself; what you get is a statement whose text is decided by your code and
whose values are decided by the user, kept apart.

## What the alternative does

Glue the value into the text instead, and the text is whatever the user typed:

```
shop=# SELECT id, name FROM customers WHERE email = 'x' OR '1'='1' LIMIT 3;
 id |      name       
----+-----------------
  1 | Helena Santos
  2 | Bruno Costa
  3 | Fábio Carvalho
(3 rows)
```

The application meant *the customer with this email*. The string it built means *any customer at
all*, and the server ran what it was given:

```
shop=# SELECT count(*) FROM customers WHERE email = 'x' OR '1'='1';
 count  
--------
 100000
(1 row)
```

That is SQL injection, and it is the whole of it: a value that was supposed to be data was placed
where it could be read as code. The classic damage is a `DROP TABLE` after a semicolon; the
commoner damage is the line above, where a login check that should have matched one row matched
everybody. Every ORM and every query builder prevents it by construction, because they never put
a value in the text.

The way it comes back is **the raw query**. Every mapper has an escape hatch for SQL it cannot
express — `raw()`, `execute()`, `find_by_sql` — and the escape hatch takes a string. Build that
string with the language's own formatting and the value is back in the text. The escape hatch also
takes parameters, in every ORM, and the rule is one line:

> **A value goes in a parameter. Never in the string. There is no exception for a value you
> trust.**

Not for an integer you validated, not for a value from your own configuration, not for a column
name — a column name cannot be a parameter, and a column name that comes from a user goes through
an allow-list of the names you accept, never into the text.

## The one thing a parameter cannot be

A placeholder stands for a **value**. It cannot stand for a table name, a column name, a keyword
or the number of items in an `IN` list. The last one is the one that catches people: `WHERE id IN
($1)` with a list as the value is one parameter holding one value, which is a list nobody can
compare against. The section before this one used `= ANY(ARRAY[…])` for exactly that reason, and with a
parameter it is `= ANY($1)` holding the whole array — one parameter, any length. An ORM that
builds `IN (?, ?, ?)` with one placeholder per item is doing the same thing the long way.

## The plan a parameter gets

Lesson 10 said it and it belongs here as well: a statement planned before its value is known is
planned for the **average** value. PostgreSQL runs the first several executions with the real
value and switches to a generic plan only when that looks no worse. Most of the time that is the
right call, and when a query is fast in `psql` and slow from the application, it is the first thing
to check. The value being separate from the text is what makes the plan reusable, and reuse is
what makes the average matter.

## What the ORM's log shows you

Every ORM's SQL log prints the statement with placeholders and the values beside it, because that
is what it sent. The log line from the server has the literals substituted back in for reading.
Neither is lying; they are the same statement from two ends, and the `$1` in one and the address in
the other is the parameter mechanism made visible.
