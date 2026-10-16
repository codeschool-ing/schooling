---
title: An index on an expression
version: 1
---

Lesson 1 section 05 showed a query slow for a reason that had nothing to do with missing indexes:
`WHERE date(placed_at) = '2025-06-01'` could not use the index on `placed_at`, because the index
holds `placed_at` values and the query asks about `date(placed_at)` values. The fix there was to
rewrite the query as a range. This section is the other way out: build the index on **the
expression the query uses**, so the index and the query speak the same terms.

## Case-insensitive e-mail

The everyday case is a login form. People type their address with capitals, `User42@Example.com`,
and the application compares in lower case:

```
market=# EXPLAIN ANALYZE SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..5147.71 rows=1000 width=26) (actual time=0.418..60.808 rows=1 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   ->  Parallel Seq Scan on customers  (cost=0.00..4047.71 rows=588 width=26) (actual time=25.602..53.560 rows=0 loops=2)
         Filter: (lower(email) = 'user42@example.com'::text)
         Rows Removed by Filter: 100000
 Planning Time: 1.432 ms
 Execution Time: 60.955 ms
(8 rows)

Time: 63.893 ms
```

**61 milliseconds** to find one customer, a parallel scan computing `lower(email)` for all 200,000
rows. The unique index on `email` is no help: it holds `user42@example.com` sorted among the
original values, and nothing in it says what their lower-case forms are.

Index the expression instead:

```
market=# CREATE INDEX customers_lower_email_idx ON customers (lower(email));
CREATE INDEX
Time: 210.386 ms

market=# EXPLAIN ANALYZE SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on customers  (cost=28.17..1850.16 rows=1000 width=26) (actual time=0.056..0.057 rows=1 loops=1)
   Recheck Cond: (lower(email) = 'user42@example.com'::text)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on customers_lower_email_idx  (cost=0.00..27.92 rows=1000 width=0) (actual time=0.045..0.046 rows=1 loops=1)
         Index Cond: (lower(email) = 'user42@example.com'::text)
 Planning Time: 0.335 ms
 Execution Time: 0.102 ms
(7 rows)

Time: 1.069 ms
```

**0.10 milliseconds.** The index stores `lower(email)` for every row, computed once when the row was
written, and the query's `WHERE` matches it exactly. The double parentheses that most expression
indexes need are not needed here because a single function call is allowed bare; anything more,
`(a + b)` or a cast, has to be wrapped in its own pair.

The match has to be **exact, in the planner's eyes**. `lower(email)` in the index serves
`lower(email) = …` in a query, and not `upper(email) = …`, nor `email ILIKE …`, nor
`lower(trim(email))`. The expression in the query must be the same expression, written the same
way, or the index is invisible. That is the price of this approach against lesson 1's: the index
works for one spelling of the question, and every query that wants it has to use that spelling.

## The statistics that come with it

Look at the `rows=1000` in both plans above. The planner had no idea how many customers have a given
`lower(email)`: `lower(email)` is not a column, so `ANALYZE` had never measured it, and the planner
fell back to a fixed guess of half a percent of the table. With one row really matching, the guess
was 1000 times too high, and the plan is a bitmap scan built for a thousand rows.

An expression index changes that, because **`ANALYZE` gathers statistics on indexed expressions**
as if they were columns:

```
market=# ANALYZE customers;
ANALYZE
Time: 434.498 ms

market=# EXPLAIN SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Index Scan using customers_lower_email_idx on customers  (cost=0.42..8.44 rows=1 width=26)
   Index Cond: (lower(email) = 'user42@example.com'::text)
(2 rows)

Time: 0.989 ms

market=# SELECT tablename, attname, n_distinct FROM pg_stats WHERE tablename = 'customers_lower_email_idx';
         tablename         | attname | n_distinct 
---------------------------+---------+------------
 customers_lower_email_idx | lower   |         -1
(1 row)

Time: 3.180 ms
```

After `ANALYZE customers`, the estimate is **1 row** and the plan a plain index scan. The last query
shows where the new numbers live: `pg_stats` has a row whose `tablename` is the **index**, with the
expression as its column, `lower`, and an `n_distinct` of -1, every value different. Everything
lesson 7 read for real columns is there for the expression.

This is sometimes worth an index on its own. A query filtering on an expression the planner keeps
misjudging can get its estimates fixed by an expression index, even if the plan then reads the table some other way. `CREATE STATISTICS`,
from lesson 7, can also gather statistics on an expression without building an index at all, and
that is the cheaper choice when only the estimate is wrong.

## The date, again

The query lesson 1 rewrote was about the day an order was placed. An index on its expression is
the obvious next step, and it fails, with an error worth a section of its own: the next one.
