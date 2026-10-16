---
title: The date that would not be indexed
version: 1
---

An index on an expression stores the expression's result for every row, computed when the row is
written, and reads it back months later. That only makes sense if the same row would give the same
result at any later moment, for anybody, under any setting. PostgreSQL enforces it: every function
in an index expression must be marked **`IMMUTABLE`**, a promise that its result depends on its
arguments and on nothing else.

## The error

```
market=# CREATE INDEX orders_placed_date_idx ON orders (date(placed_at));
ERROR:  functions in index expression must be marked IMMUTABLE
Time: 1.401 ms

market=# SELECT provolatile FROM pg_proc WHERE oid = 'date(timestamp with time zone)'::regprocedure;
 provolatile 
-------------
 s
(1 row)

Time: 1.854 ms
```

`functions in index expression must be marked IMMUTABLE`, and `pg_proc` says why: `date()` of a
`timestamptz` is marked **`s`, stable**. Stable means "the same within one statement", which is a
weaker promise, and the query after it shows what the function depends on besides its argument.

## What it depends on

```
market=# SET TimeZone = 'UTC';
SET
Time: 0.773 ms

market=# SELECT date(timestamptz '2025-06-01 22:30-03');
    date    
------------
 2025-06-02
(1 row)

Time: 0.569 ms

market=# SET TimeZone = 'America/Sao_Paulo';
SET
Time: 0.383 ms

market=# SELECT date(timestamptz '2025-06-01 22:30-03');
    date    
------------
 2025-06-01
(1 row)

Time: 0.424 ms
```

The same instant, 22:30 on 1 June in São Paulo, is **2 June** for a session whose `TimeZone` is
UTC, and **1 June** for one in São Paulo. A `timestamptz` is a moment, not a calendar date, and
which day a moment falls on depends on where you stand. `date()` asks the session's `TimeZone`
setting, so its result for one row can change between two sessions, or between two deployments of
the same application.

Now imagine the index had been allowed. It would hold each order's date as computed by whatever
session built it. A session with a different `TimeZone` would ask the index for `2025-06-01`, get
the rows that were the first of June for somebody else, and receive a wrong answer with no error.
An index that disagrees with the table is the worst kind of wrong, and the `IMMUTABLE` rule exists
to make it impossible.

## Making the expression immutable

The fix is to remove the dependency, by saying which time zone the day is counted in. `AT TIME
ZONE 'America/Sao_Paulo'` turns the moment into a local time in a named zone, whatever the session
says, and the cast to `date` of that is immutable:

```
market=# CREATE INDEX orders_placed_date_idx ON orders (((placed_at AT TIME ZONE 'America/Sao_Paulo')::date));
CREATE INDEX
Time: 1076.044 ms (00:01.076)

market=# EXPLAIN SELECT count(*) FROM orders WHERE (placed_at AT TIME ZONE 'America/Sao_Paulo')::date = '2025-06-01';
                                                 QUERY PLAN                                                  
-------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=15406.29..15406.30 rows=1 width=8)
   ->  Bitmap Heap Scan on orders  (cost=113.93..15381.29 rows=10000 width=0)
         Recheck Cond: (((placed_at AT TIME ZONE 'America/Sao_Paulo'::text))::date = '2025-06-01'::date)
         ->  Bitmap Index Scan on orders_placed_date_idx  (cost=0.00..111.43 rows=10000 width=0)
               Index Cond: (((placed_at AT TIME ZONE 'America/Sao_Paulo'::text))::date = '2025-06-01'::date)
(5 rows)

Time: 1.997 ms

market=# ANALYZE orders;
ANALYZE
Time: 268.478 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE (placed_at AT TIME ZONE 'America/Sao_Paulo')::date = '2025-06-01';
                                                                 QUERY PLAN                                                                 
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=58.79..58.80 rows=1 width=8) (actual time=0.713..0.714 rows=1 loops=1)
   ->  Index Scan using orders_placed_date_idx on orders  (cost=0.43..54.62 rows=1668 width=0) (actual time=0.062..0.567 rows=2801 loops=1)
         Index Cond: (((placed_at AT TIME ZONE 'America/Sao_Paulo'::text))::date = '2025-06-01'::date)
 Planning Time: 0.247 ms
 Execution Time: 0.760 ms
(5 rows)

Time: 1.570 ms

market=# EXPLAIN SELECT count(*) FROM orders WHERE date(placed_at) = '2025-06-01';
                                       QUERY PLAN                                       
----------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=30177.63..30177.64 rows=1 width=8)
   ->  Gather  (cost=30177.42..30177.63 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=29177.42..29177.43 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=4167 width=0)
                     Filter: (date(placed_at) = '2025-06-01'::date)
(6 rows)

Time: 0.804 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders_placed_at_idx', 'orders_placed_date_idx');
        relname         | size  
------------------------+-------
 orders_placed_at_idx   | 43 MB
 orders_placed_date_idx | 14 MB
(2 rows)

Time: 1.080 ms
```

Four things in that block.

- **The index was accepted**, because the expression no longer asks the session anything. The
  extra parentheses are required: anything more than a single function call has to be wrapped.
- **The first estimate was 10,000 rows**, half a percent of the table, the same fixed guess the
  previous section met: the index existed and `ANALYZE` had not yet measured its expression. After
  `ANALYZE orders` the estimate is **1668** against **2801** real, now from a histogram of days.
- **The query took 0.76 milliseconds**, against the 119 of lesson 1's original and the 1.3 of its
  range rewrite.
- **`date(placed_at)` still gets a sequential scan.** The index serves the expression it was built
  on, written the same way, and nothing else, as the previous section said.

## Index the expression, or rewrite the query?

Lesson 1 rewrote this query as a range on `placed_at`, and that answer needed no new index: the
existing one served it in 1.3 milliseconds. The expression index answers in 0.8, and costs **14 MB**
of disk and an extra entry to maintain on every order written, beside the 43 MB index on
`placed_at` that is still needed for everything else.

So the rewrite is usually the better choice when you can change the query. The expression index is
the right one when you cannot: an ORM that generates `date(...)`, a report tool, a query that
groups by the day as well as filtering on it. Either way, the day an order belongs to depends on a
time zone, and writing that time zone down is a decision about the business, not about the index.

This lesson built indexes and a table on `market`. Close `psql` and put the database back as lesson
3 starts:

```sh
~/reset-market.sh
```
