---
title: What the planner knows about a table
version: 1
---

The planner chooses a plan before it reads a single row of the table. It has to: reading the rows
is the work the plan is meant to organise. **So it decides from a summary**, kept in two system
catalogs, and the summary is only as recent as the last time somebody wrote it.

The size of each table is in `pg_class`:

```
shop=# SELECT relname, reltuples, relpages FROM pg_class WHERE relname IN ('orders', 'customers');
  relname  | reltuples | relpages 
-----------+-----------+----------
 customers |     50000 |      568
 orders    |     1e+06 |     8334
(2 rows)
```

`reltuples` is the number of rows and `relpages` the number of 8 kB pages, both as they were the
last time `VACUUM` or `ANALYZE` looked. Lesson 4 met the pages as the files on disk; here they are
one of the two numbers every cost estimate starts from.

What is inside each column is in `pg_statistic`, which is hard to read directly, so PostgreSQL
puts a view over it called `pg_stats`. One row per column:

```
shop=# SELECT attname, null_frac, n_distinct FROM pg_stats WHERE tablename = 'orders';
   attname   | null_frac | n_distinct 
-------------+-----------+------------
 id          |         0 |         -1
 customer_id |         0 |      49325
 status      |         0 |          3
 total_cents |         0 |      49325
 created_at  |         0 |      87417
(5 rows)

shop=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';
     most_common_vals     |       most_common_freqs       
--------------------------+-------------------------------
 {paid,cancelled,shipped} | {0.6027333,0.19946666,0.1978}
(1 row)
```

Three columns of that view do most of the work.

- **`null_frac`** is the share of rows where the column is null. Every column of `orders` is
  `NOT NULL`, so it is 0 everywhere.
- **`n_distinct`** is how many different values the column holds. A positive number is a count; a
  negative one is a fraction of the rows, so that it stays right as the table grows. `-1` on `id`
  says every row has its own value, which is what a primary key is.
- **`most_common_vals`** and **`most_common_freqs`** are the frequent values and the share of rows
  each one takes. `status` has three values, and the list names all of them.

## From the summary to an estimate

Ask for a plan and look only at `rows=`, the number of rows the planner expects a step to produce:

```
shop=# EXPLAIN SELECT * FROM orders WHERE status = 'cancelled';
                           QUERY PLAN                           
----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..20834.00 rows=199467 width=34)
   Filter: (status = 'cancelled'::text)
(2 rows)

shop=# EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=4.58..81.89 rows=20 width=34)
   Recheck Cond: (customer_id = 42)
   ->  Bitmap Index Scan on orders_customer_id  (cost=0.00..4.58 rows=20 width=0)
         Index Cond: (customer_id = 42)
(4 rows)
```

Both numbers are arithmetic on what you just read. `cancelled` takes 0.19946666 of the rows, and
0.19946666 × 1,000,000 is 199,467: **the estimate is the frequency times the row count**, exactly.
`42` is not in any list of common values, so the planner assumes the customers share the table
evenly: 1,000,000 rows over 49,325 distinct values is 20 rows each.

The truth is 200,000 cancelled orders and 20 orders for every customer, because lesson 4's
generator made them by arithmetic. **The estimates are close and not exact, because `ANALYZE`
reads a sample** — 30,000 rows of this table, chosen at random — and a sample of a million rows
misses by a little. Your frequencies and your `n_distinct` will differ in the last digits from
these, and they move again every time the table is analysed. A plan does not care about the last
digit. It cares about the difference between twenty and twenty thousand.

`pg_stats` has more columns than these: `histogram_bounds`, which serves range conditions such as
`created_at > …`, and `correlation`, which says how well the physical order of the rows follows the
column. `db-performance` lesson 7 reads them, and the extended statistics that join two columns.
What matters for administering the server is simpler. **Every estimate is made from this
summary, and nothing updates the summary except `ANALYZE`**, run by hand or by autovacuum. When the
table changes and the summary does not, the planner goes on deciding about a table that no longer
exists.
