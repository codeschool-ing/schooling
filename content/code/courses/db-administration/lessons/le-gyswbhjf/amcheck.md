---
title: amcheck, which asks an index whether it is still right
version: 1
---

A corrupt index gives no sign of itself until a query reads the wrong page, and then the sign is a
wrong answer, which nobody reports as an error. **`amcheck` reads an index and checks it against
its own rules**, so you can ask the question before a user does. It is one of the extensions that
come with PostgreSQL itself, already installed with the server package, and lesson 18 is about
extensions in general.

```
shop=# CREATE EXTENSION amcheck;
CREATE EXTENSION

shop=# SELECT c.relname, bt_index_check(c.oid, heapallindexed => true) FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am am ON am.oid = c.relam WHERE am.amname = 'btree' AND c.relnamespace = 'public'::regnamespace;
       relname       | bt_index_check 
---------------------+----------------
 customers_pkey      | 
 customers_email_key | 
 orders_pkey         | 
 orders_customer_id  | 
 orders_created_at   | 
(5 rows)
```

`bt_index_check` checks one B-tree index, the ordinary kind, and the query runs it over every
B-tree index in the `public` schema. **An empty result for a row is the good answer**: the function
returns nothing when it finds nothing, and raises an error when it finds a problem.

Without options it checks that the entries inside each page are in order and that each page agrees
with its neighbours. **`heapallindexed => true` adds the check that matters most**: it reads the
table and confirms that every row has its entry in the index, which is the corruption that makes a
query miss rows. It takes longer, roughly a read of the table, and both take only the lock a
`SELECT` takes, so they are safe on a live server. `bt_index_parent_check` checks more, the links
between levels of the tree, and takes a lock that blocks writes while it runs.

For a whole database there is a command-line tool, `pg_amcheck`. Ubuntu does not put it on the
`PATH`, so it is called by its full path:

```
ana@db:~$ /usr/lib/postgresql/16/bin/pg_amcheck --heapallindexed shop && echo clean
clean
```

`pg_amcheck` itself printed nothing, and `echo` ran because it returned success: everything it
checked passed,
every B-tree index, and every table as well, which amcheck can also read for damage. In version 16
nothing in amcheck checks a GIN or GiST index.

## An index that disagrees with its table

A clean result is the usual one, so here is an index built to be wrong, the same way an index on
text goes wrong after a glibc change: **built under one set of rules, read under another.** The
rules here are a time zone, and the culprit is a function that promises more than it can keep.

```
shop=# CREATE FUNCTION order_day(ts timestamptz) RETURNS date LANGUAGE sql IMMUTABLE AS $$ SELECT ts::date $$;
CREATE FUNCTION

shop=# CREATE TABLE day_check AS SELECT id, created_at FROM orders WHERE id <= 100000;
SELECT 100000

shop=# SET TimeZone = 'America/Sao_Paulo';
SET

shop=# CREATE INDEX day_check_day ON day_check (order_day(created_at));
CREATE INDEX

shop=# ANALYZE day_check;
ANALYZE

shop=# SELECT bt_index_check('day_check_day', heapallindexed => true);
 bt_index_check 
----------------
 
(1 row)

shop=# SET TimeZone = 'UTC';
SET

shop=# EXPLAIN (COSTS OFF) SELECT min(created_at), max(created_at) FROM day_check WHERE order_day(created_at) = '2026-01-02';
                               QUERY PLAN                               
------------------------------------------------------------------------
 Aggregate
   ->  Bitmap Heap Scan on day_check
         Recheck Cond: (order_day(created_at) = '2026-01-02'::date)
         ->  Bitmap Index Scan on day_check_day
               Index Cond: (order_day(created_at) = '2026-01-02'::date)
(5 rows)

shop=# SELECT min(created_at), max(created_at) FROM day_check WHERE order_day(created_at) = '2026-01-02';
          min           |          max           
------------------------+------------------------
 2026-01-02 03:00:01+00 | 2026-01-03 02:56:01+00
(1 row)

shop=# SELECT bt_index_check('day_check_day', heapallindexed => true);
ERROR:  heap tuple (408,120) from table "day_check" lacks matching index tuple within index "day_check_day"
HINT:  Retrying verification using the function bt_index_parent_check() might provide a more specific error.

shop=# RESET TimeZone;
RESET

shop=# DROP TABLE day_check;
DROP TABLE

shop=# DROP FUNCTION order_day;
DROP FUNCTION

shop=# DROP EXTENSION amcheck;
DROP EXTENSION
```

An index on an expression is only allowed when the expression is `IMMUTABLE`: the same input gives
the same output forever. `order_day` says it is, and it is not, **because which day a moment falls
on depends on the session's `TimeZone`**. The index was built in São Paulo time, set just before it
so the demonstration works in whatever zone your server keeps, and the first check passed: under the rules it was built with, the index was right.

Then the session switched to UTC. The plan uses the index, as it should, and asked for 2 January it
returns orders stamped from 03:00 on 2 January to nearly 03:00 on 3 January in UTC: São Paulo's
2 January, not the one asked for. **The query got a wrong answer and no error.** The second check
caught it: `heapallindexed` computed `order_day` for a row of the table under the current rules,
looked for that entry in the index and did not find it, and the message names the row by its
physical position.

That is the whole family. A collation that changed under a text index, a function marked
`IMMUTABLE` that is not, a disk that dropped a write: each leaves an index whose entries do not
match what the table says now, and `bt_index_check` with `heapallindexed` is how to find one.
**Rebuilding fixes only the first and the last.** For a lying function, `REINDEX` would build the
index under whatever time zone the session has and break it for the other one; the fix is a
function that tells the truth, such as one that converts with
`AT TIME ZONE 'America/Sao_Paulo'` before taking the date, and then the rebuild. Everything made
here is dropped again, the extension included.
