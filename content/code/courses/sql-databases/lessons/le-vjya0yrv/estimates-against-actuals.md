---
title: When the planner is wrong, and why
version: 1
---

The planner does not run the query to choose a plan. It predicts how many rows each step will
produce, prices each plan on that prediction, and picks the cheapest. **Every bad plan in this
lesson's sense is a wrong prediction** — the planner did the right thing for the numbers it had,
and the numbers were wrong.

So the way to read a plan is to compare `rows=` in the estimate with `rows=` in the actual, on every
node, and stop at the first big gap. A factor of two is noise. A factor of a hundred is the
finding.

## A function hides the column

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE date(placed_at) = DATE '2025-03-01';
                                                 QUERY PLAN                                                  
-------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..22466.00 rows=5000 width=28) (actual time=0.129..114.541 rows=1834 loops=1)
   Filter: (date(placed_at) = '2025-03-01'::date)
   Rows Removed by Filter: 998166
 Planning Time: 0.238 ms
 Execution Time: 114.682 ms
(5 rows)
```

Estimated 5000, actual 1834. The planner has statistics about `placed_at` — its range, its
distribution — and none about `date(placed_at)`, because a function's result is not a column. So
it fell back to a default: half a percent of the table, whatever the table. That guess is wrong in
both directions on different days, and a plan built on it will sometimes be the wrong plan.

Lesson 9 gave the rewrite, and it fixes both problems at once:

```sql
WHERE placed_at >= DATE '2025-03-01' AND placed_at < DATE '2025-03-02'
```

A range on the bare column has statistics behind it and an index in front of it. The same is true
of every expression in lesson 9's list of reasons an index is not used — arithmetic, a cast, a
`coalesce` — and the estimate is the second casualty each time.

## Statistics that were never collected

```sql
CREATE TABLE returns (
    id        integer PRIMARY KEY,
    order_id  integer NOT NULL REFERENCES orders (id),
    reason    text NOT NULL,
    opened_at timestamptz NOT NULL
);
```

A new table, empty, and a plan for a query on it:

```
shop=# EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
                       QUERY PLAN                        
---------------------------------------------------------
 Seq Scan on returns  (cost=0.00..23.38 rows=5 width=48)
   Filter: (reason = 'damaged'::text)
(2 rows)
```

`rows=5`, because the table has never been analysed and the planner is guessing from its size on
disk, which is nothing. Now two hundred thousand rows are loaded, and the same `EXPLAIN` is run
again, without doing anything else:

```
shop=# EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
                         QUERY PLAN                          
-------------------------------------------------------------
 Seq Scan on returns  (cost=0.00..3293.54 rows=754 width=48)
   Filter: (reason = 'damaged'::text)
(2 rows)
```

The cost went up — the planner can see the table is bigger — but `rows=754` is still a guess
scaled from nothing, and the truth is forty times that. Then:

```
shop=# ANALYZE returns;
ANALYZE

shop=# EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
                          QUERY PLAN                           
---------------------------------------------------------------
 Seq Scan on returns  (cost=0.00..3909.00 rows=33400 width=26)
   Filter: (reason = 'damaged'::text)
(2 rows)
```

`rows=33400`, which is a quarter of two hundred thousand, which is right: four reasons, evenly
spread. One statement, and the planner went from guessing to knowing.

Autovacuum runs `ANALYZE` on its own once a table has changed enough, and on a table that grows
slowly that is fine. On a table that was just loaded, or just had half its rows rewritten, the
window between the change and the next automatic analysis is where the bad plans live. That is
lesson 9's *"it was fast yesterday"*, and it is why `ANALYZE` after a bulk load is not optional.

## Columns that move together

The planner assumes conditions are independent. On an `addresses` table, `WHERE city = 'Manaus'
AND state = 'AM'` is estimated as the product of the two selectivities, as if an address in
Manaus could be in any state. So the estimate is far too low, the planner picks a nested loop for
a result it thinks is tiny, and the loop runs a hundred thousand times.

PostgreSQL 10 and later can be told the two columns are related:

```sql
CREATE STATISTICS addresses_city_state ON city, state FROM addresses;
ANALYZE addresses;
```

After that the planner has a joint distribution and the estimate is honest. Look for this whenever
a plan under-estimates a multi-column `WHERE` by orders of magnitude and each column alone is
estimated fine. It is the shape of the problem, and it is common on address data, on status
columns that depend on a type column, and on anything denormalised the way lesson 2 discussed.

## The value the plan was made for

A prepared statement, or a query an ORM sends with placeholders, is planned before its value is
known. Lesson 11 has the mechanism; what matters here is the consequence: **a plan for `$1` is a
plan for the average value**, and the average value of `status` is `paid`, at sixty percent. A
plan good for `paid` is a sequential scan, and it is the wrong plan for `pending`, at a third of a
percent. PostgreSQL plans the first few executions with the real value and switches to a generic
plan only when that looks no worse; when a query is fast in `psql` and slow from the application,
this is the first thing to suspect.

## Reading the gap

| estimate against actual | usual cause |
|---|---|
| way under, on a scan with a function or arithmetic | no statistics for the expression |
| way under or over on a newly loaded table | never analysed |
| way under on a multi-column condition | correlated columns |
| right on every scan, wrong above a join | the join's selectivity, and the order the joins were tried in |
| fine in `psql`, wrong from the application | a generic plan for a placeholder |

The one habit that finds all of them: **read the estimates from the bottom up, and the first node
where the two numbers disagree by a factor of a hundred is where the plan went wrong** — every
node above it inherited that mistake.
