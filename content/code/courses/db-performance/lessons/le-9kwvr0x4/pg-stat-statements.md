---
title: The server keeps the score
version: 1
---

When somebody says "the database is slow", the instinct is to open `psql`, run the query you
suspect and time it. That answers a question about one query, and it was never the question. The
question is **where the server's time goes**, and for that you need a record of everything it
ran, which no single person watching a terminal has.

PostgreSQL can keep that record. The extension `pg_stat_statements` watches every statement the
server executes and adds it to a running tally: how many times it ran, how long it took in total,
the fastest and the slowest, how many rows it returned, how many pages it read. `sql-databases`
lesson 10 switched it on for a moment; this course leaves it on for good, because almost every
lesson from here starts by asking it something.

## Switching it on

The extension comes with PostgreSQL, but it has to be **loaded when the server starts**, because
it hooks into the code that executes every query. That is the setting `shared_preload_libraries`,
and a setting read at start-up only changes with a restart:

```
market=# ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM
Time: 6.728 ms
ana@vm:~$ sudo systemctl restart postgresql
market=# CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION
Time: 18.724 ms
```

Three steps, and the order matters. `ALTER SYSTEM` writes the setting into a file the server reads
at start-up, `postgresql.auto.conf`, and changes nothing yet. The restart loads the library.
`CREATE EXTENSION` then creates, inside `market`, the view you query. Skip the restart and
`CREATE EXTENSION` still succeeds, but the first query against the view refuses, saying the
library must be loaded via `shared_preload_libraries`.

`ALTER SYSTEM` needs a superuser, which is what lesson 1 made your role. On a managed service you
cannot run it; the provider has its own switch, and most turn this extension on by default,
because nobody can run a database well without it.

## What one row means

The view has one row per **distinct statement**, and "distinct" is decided after the constants are
taken out. `WHERE customer_id = 17` and `WHERE customer_id = 90210` are the same statement as far as
the extension is concerned, stored once as `WHERE customer_id = $1`, with a number called
`queryid` that identifies that shape. That is what makes the record useful: a screen that runs the
same query a million times with a million different customers is one row with a large count,
rather than a million rows with a count of one.

The columns this course reads most:

| column | what it says |
|---|---|
| `calls` | how many times the statement ran |
| `total_exec_time` | the sum of every run, in milliseconds |
| `mean_exec_time`, `min_exec_time`, `max_exec_time`, `stddev_exec_time` | the average, the extremes and how spread out the runs were |
| `rows` | the rows returned or affected, added up over every call |
| `shared_blks_hit`, `shared_blks_read` | pages found in PostgreSQL's memory, and pages it had to ask the operating system for |
| `query` | the statement, with its constants replaced by `$1`, `$2`… |

The times are the **server's own**: from when it began executing to when it finished, without the
trip across the connection that lesson 1's `\timing` includes. And they are counted **since the last
reset**, either a call to `pg_stat_statements_reset()` or, as lesson 2's way back to the known rows
does, a fresh database. A tally always has a start, and a number in it means nothing until you know
when that was.

The record is empty for now, apart from the statements you just typed. The next section gives the
server something to count.
