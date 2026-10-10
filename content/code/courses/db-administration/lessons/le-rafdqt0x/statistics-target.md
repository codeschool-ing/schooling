---
title: How much of the table the sample reads
version: 1
---

`ANALYZE` on a table of a billion rows finishes in seconds, which is the first sign that **it does
not read the table**. It reads a sample, and one setting decides how big the sample is and how much
of what it found is kept.

```
shop=# SHOW default_statistics_target;
 default_statistics_target 
---------------------------
 100
(1 row)

shop=# \timing on
Timing is on.

shop=# ANALYZE VERBOSE orders;
INFO:  analyzing "public.orders"
INFO:  "orders": scanned 8334 of 8334 pages, containing 1000000 live rows and 0 dead rows; 30000 rows in sample, 1000000 estimated total rows
ANALYZE
Time: 119.425 ms
```

`VERBOSE` makes `ANALYZE` say what it did. The line to read is **`30000 rows in sample`**: the
sample is 300 rows for every unit of the statistics target, and the target is 100. On `orders` the
sample is drawn from all 8,334 pages, because the table is small; on a table of a million pages it
would still be 30,000 rows, taken from 30,000 of them. That is why the time barely grows with the
table, and why the frequencies of the first section were close and not exact.

The same number caps what is kept for each column: **up to 100 entries in the list of common
values, and a histogram of 100 buckets**, which `pg_stats` stores as 101 boundaries.

## Raising it for one column

The target can be set per column, and the column with the largest target decides the size of the
sample for the whole table:

```
shop=# ALTER TABLE orders ALTER COLUMN total_cents SET STATISTICS 1000;
ALTER TABLE
Time: 1.335 ms

shop=# ANALYZE VERBOSE orders;
INFO:  analyzing "public.orders"
INFO:  "orders": scanned 8334 of 8334 pages, containing 1000000 live rows and 0 dead rows; 300000 rows in sample, 1000000 estimated total rows
ANALYZE
Time: 752.260 ms

shop=# \timing off
Timing is off.

shop=# SELECT attname, attstattarget FROM pg_attribute WHERE attrelid = 'orders'::regclass AND attnum > 0;
   attname   | attstattarget 
-------------+---------------
 id          |            -1
 customer_id |            -1
 status      |            -1
 total_cents |          1000
 created_at  |            -1
(5 rows)

shop=# SELECT attname, array_length(histogram_bounds, 1) AS bounds FROM pg_stats WHERE tablename = 'orders' AND attname IN ('customer_id', 'total_cents');
   attname   | bounds 
-------------+--------
 customer_id |    101
 total_cents |   1001
(2 rows)
```

Ten times the target, ten times the sample: 300,000 rows, and the `ANALYZE` took 752.260 ms where
it had taken 119.425 ms. `attstattarget` shows which column carries a setting of its own, and `-1`
means it follows `default_statistics_target`. The histogram of `total_cents` now has 1,001
boundaries and `customer_id` keeps its 101, although both were computed from the same larger
sample.

**A bigger target costs on every `ANALYZE` of that table, and on every plan that uses the column**,
because the planner walks longer lists. That is why it is raised column by column, where an
estimate was seen to be wrong, and almost never through `default_statistics_target`, which would
raise it for every column of every table at once.

The column that earns it has more values that matter than a list of 100 can hold: a `country` or a
`product_id` where a few hundred values carry most of the rows and the rest trail off, so a value
just outside the list is estimated as if it were average. The way to find one is the comparison the
previous section made — estimate against actual in `EXPLAIN ANALYZE`, on that column's condition —
and `db-performance` lesson 7 goes through the histogram and the common values in detail.

Put `orders` back the way it was, and analyse it again so its summary is built at the default:

```
shop=# ALTER TABLE orders ALTER COLUMN total_cents SET STATISTICS -1;
ALTER TABLE

shop=# ANALYZE orders;
ANALYZE
```

There is one more override, for the case where the sample keeps getting one number wrong.
`n_distinct` is the estimate a sample is worst at, and a column whose distinct count you know can be
told it, as a count or as a negative fraction:

```sql
ALTER TABLE orders ALTER COLUMN customer_id SET (n_distinct = 50000);
```

It takes effect at the next `ANALYZE`. It is shown and not run, because the sample gets this
column right to within a couple of percent, and an override that is right today is wrong when the
customers double.
