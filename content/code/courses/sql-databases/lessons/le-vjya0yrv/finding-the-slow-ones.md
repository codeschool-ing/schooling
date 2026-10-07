---
title: Which query is the slow one
version: 1
---

The lesson before this one ended on a rule: add an index because you looked. This lesson is the
looking, and it starts one step earlier than most people do — before you can read a plan, you have
to know **which** query to read the plan of.

The wrong way to find it is to wait for a complaint. The complaint names a screen, the screen runs
six queries, and the one that is slow is not the one the person guessed. The right way is to ask
the database, which has been counting.

## The database keeps the score

PostgreSQL's `pg_stat_statements` extension records every distinct statement the server has run,
with how many times and for how long. It has to be loaded at start-up — `shared_preload_libraries`
in the configuration — and then it is a table you can query like any other.

Switching it on is three commands, and the middle one restarts the server, because a library
loaded at start-up is only read at start-up:

```
ana@vm:~$ psql shop -c "ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql shop -c "CREATE EXTENSION pg_stat_statements"
CREATE EXTENSION
```

Then the shop needs some traffic to have a score. This file is a morning of an application's
queries compressed into a few seconds — `\gexec` runs every row a `SELECT` returns as a statement
of its own, so each line below sends the same query many times with different values:

```sql
-- traffic.sql: a morning of the shop's queries, a few seconds long.
SELECT pg_stat_statements_reset();

SELECT 'SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city'
FROM generate_series(1, 3) \gexec

SELECT format('SELECT count(*) FROM orders WHERE status = %L', (ARRAY['paid', 'shipped', 'cancelled'])[1 + n % 3])
FROM generate_series(1, 30) AS n \gexec

SELECT $$SELECT * FROM orders WHERE date(placed_at) = DATE '2025-03-01'$$ \gexec

SELECT format('SELECT id, name FROM customers WHERE email = %L', 'user' || n * 211 || '@example.com')
FROM generate_series(1, 400) AS n \gexec

SELECT format('SELECT id, total FROM orders WHERE customer_id = %s', n * 613)
FROM generate_series(1, 150) AS n \gexec
```

```
ana@vm:~$ psql shop -f traffic.sql >/dev/null
```

Here is what the server kept:

```
shop=# SELECT calls, round(total_exec_time::numeric) AS total_ms, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 5;
 calls | total_ms | mean_ms |                          query                          
-------+----------+---------+---------------------------------------------------------
   150 |     3532 |    23.5 | SELECT id, total FROM orders WHERE customer_id = $1
     3 |      404 |   134.7 | SELECT c.city, count(*) FROM customers c JOIN orders o 
    30 |      297 |     9.9 | SELECT count(*) FROM orders WHERE status = $1
     1 |       47 |    47.1 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
   400 |        5 |     0.0 | SELECT id, name FROM customers WHERE email = $1
(5 rows)
```

Three things to read off that table, and they are the three things the tool exists for.

**The literals are gone.** `WHERE email = $1`, not `WHERE email = 'user211@example.com'`. Four hundred
lookups by four hundred different addresses are one row, because they are one query — which is
what you want when the question is "what is this application doing", and it is why the tool is
worth more than the log below.

**Sort by total, not by mean.** The query at the top takes 23 milliseconds, which nobody would
call slow, and it ran a hundred and fifty times: three and a half seconds of the server, more than
everything else on the list together. The city report below it is nearly six times slower per call
and costs about a ninth as much, because it ran three times. A query at one millisecond that runs
a million times a day is a thousand seconds of database time, and it never appears in anybody's
complaint.

**The mean is the other list**, and it is where a user's experience lives:

```
shop=# SELECT calls, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 3;
 calls | mean_ms |                          query                          
-------+---------+---------------------------------------------------------
     3 |   134.7 | SELECT c.city, count(*) FROM customers c JOIN orders o 
     1 |    47.1 | SELECT * FROM orders WHERE date(placed_at) = DATE $1
   150 |    23.5 | SELECT id, total FROM orders WHERE customer_id = $1
(3 rows)
```

The city report is first, at 135 milliseconds a call, and the `date(placed_at)` query ran once and
took 47. Somebody waited for each. Lesson 9 said why the second is slow, and the section on
estimates in this lesson shows what the plan says about it. The lookup by `customer_id`, top of the
other list, is third here — and the next section starts with it.

Two lists, two questions: **what is costing the server the most**, and **what is costing a person
the most**. Work the first when the machine is busy and the second when somebody is unhappy, and
check both, because they disagree more often than not.

## The log, for the ones that are only sometimes slow

`pg_stat_statements` averages. A query that is fast a thousand times and takes ten seconds once is
a fast query on that table. The other tool catches the once. `log_min_duration_statement` writes
every statement slower than a threshold to the server's log, and a superuser can set it without a
restart:

```
shop=# ALTER SYSTEM SET log_min_duration_statement = '100ms';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

A hundred milliseconds, so that this server's city report crosses it. Run the report twice and read
the end of the log — the file `pg_lsclusters` named in lesson 1:

```
ana@vm:~$ psql shop -c "SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;" >/dev/null
ana@vm:~$ psql shop -c "SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;" >/dev/null
ana@vm:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-07 07:57:31.963 UTC [11417] ana@shop LOG:  duration: 149.903 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
2026-10-07 07:57:32.191 UTC [11426] ana@shop LOG:  duration: 180.310 ms  statement: SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
```

Each line has the time, the process, who asked and in which database — `ana@shop` — then the
duration and the **full text, literals included**. The literals are the point here. When a query is slow only for one customer, the log has the
customer, and the plan you take next has to be run with that value and not with a placeholder.
A plan for `$1` is a plan for nobody in particular, and the section on estimates says why that can
be a different plan.

Where to set the threshold is a decision, and a low one on a busy server writes a log faster than
anybody reads it. A few hundred milliseconds is where most people start, and it comes down as the
obvious ones are fixed. On your own machine, put it back when you have looked:

```
shop=# ALTER SYSTEM RESET log_min_duration_statement;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

MySQL has the same two tools under other names: the slow query log, with `long_query_time`, and
the `performance_schema` tables, which `sys.statement_analysis` summarises in the same shape as
the table above. Lesson 12 has the differences.

## What you now have

A query, with the value it was slow for, and a number for how slow. That is the input to
everything else in this lesson, and it is worth insisting on: **a plan without a measurement to
compare it against is a plan you cannot tell you have improved.**
