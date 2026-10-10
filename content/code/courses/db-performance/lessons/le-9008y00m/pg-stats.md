---
title: What ANALYZE leaves behind
version: 1
---

The planner does not look at your rows when it plans a query. It cannot afford to: counting how
many orders seller 42 has, in order to decide how to find seller 42's orders, would cost as much as
the query itself. What it reads instead is a **summary per column**, written by `ANALYZE` from a
sample of the table and kept in the catalogue until the next `ANALYZE` replaces it. Every
estimate in every plan of this course came out of that summary, and this lesson reads it.

The belief worth dropping first is that the summary is a small copy of the data. It is not. It is
a handful of numbers and two short lists, at most a hundred common values and a hundred and one
histogram bounds per column out of the box, made from a sample whose size one setting decides:

```
market=# SHOW default_statistics_target;
 default_statistics_target 
---------------------------
 100
(1 row)

Time: 0.498 ms
```

**100** is the default. `ANALYZE` reads 300 rows for every unit of it, so **30,000 rows** of each
table, whether the table has a thousand rows or two million. Lesson 6 looked at when that sample
is taken and what happens when it is old; this lesson is about what is written down from it.

## The view: `pg_stats`

The summary lives in the catalogue table `pg_statistic`, in a layout made for the planner and not
for people. `pg_stats` is the readable view over it, one row per column of every table, and it
only shows the columns you are allowed to read. That filter is there for a reason. The summary
holds **real values from the table**, the commonest ones copied as they are, and a view that
showed them to anybody would leak a salary or an e-mail address to a user who cannot select the
column itself.

The fields that matter for estimates are these:

| field | what it holds |
|---|---|
| `null_frac` | the fraction of the sample that was NULL |
| `n_distinct` | how many different values the column has: a count, or a fraction of the rows when negative |
| `most_common_vals` and `most_common_freqs` | the values seen most often, and the fraction of rows each one is |
| `histogram_bounds` | the rest of the values, cut into buckets that hold the same number of rows each |
| `correlation` | how closely the order of the values follows the order of the rows on disk, from -1 to 1 |

Ask for the short ones across `orders` and `events`:

```
market=# SELECT attname, null_frac, n_distinct, correlation FROM pg_stats WHERE tablename = 'orders' ORDER BY attname;
   attname   | null_frac | n_distinct | correlation  
-------------+-----------+------------+--------------
 customer_id |         0 |     184161 | 0.0064027454
 id          |         0 |         -1 |            1
 placed_at   |         0 |         -1 |            1
 seller_id   |         0 |       1000 |   0.07900135
 status      |         0 |          4 |    0.9481103
 total_cents |         0 |      49324 |   0.00571455
(6 rows)

Time: 4.783 ms

market=# SELECT attname, null_frac, n_distinct FROM pg_stats WHERE tablename = 'events' ORDER BY attname;
   attname   | null_frac | n_distinct  
-------------+-----------+-------------
 at          |         0 |          -1
 customer_id |    0.3054 |      181538
 id          |         0 |          -1
 kind        |         0 |           4
 payload     |         0 | -0.77623963
(5 rows)

Time: 1.345 ms
```

Every line says something you can check against `market.sql` from lesson 1.

- **`orders.id` and `placed_at` show `-1` distinct values.** A negative `n_distinct` is a fraction
  of the rows, and -1 means "as many as there are rows": every value different. The planner keeps
  it as a fraction because a fraction stays right as the table grows, where a count of two million
  would be wrong the day after.
- **`status` has 4 and `seller_id` 1000**, written as counts, because those numbers do not grow
  with the table. `ANALYZE` chooses between the two forms itself: it writes a fraction when it
  believes the number of values grows with the rows.
- **`events.customer_id` has a `null_frac` of 0.3054.** `market.sql` made three events in ten
  anonymous, and the sample saw 30.5% of them. Any condition on `customer_id` is applied to the
  other 69.5% only, and that is where the fraction is used.
- **`placed_at` and `id` have a correlation of 1**, because `market.sql` wrote the orders in the
  order they were placed. `customer_id` has 0.0064: customer numbers are scattered across the table
  at random. Section 04 is about what the planner does with that.
- **`payload` on `events` has `-0.77623963`**: about 78% of the payloads are different from each
  other. Two random numbers in a JSON object collide sometimes, and the sample saw how often.

None of these was counted over the whole table. They are what 30,000 rows looked like, and each
section of this lesson is one of these fields and the way a single wrong number in it turns into a
wrong plan.

## From a field to an estimate

The planner's arithmetic is always the same shape. For each condition in a `WHERE` clause it works
out a **selectivity**, the fraction of the rows it expects to pass, from the fields above. It then
multiplies the selectivities of the conditions together and the result by the number of rows the
table has, which comes from `reltuples` in `pg_class` and not from `pg_stats`. The answer is the
`rows=` figure on a plan node.

So when an estimate is wrong, there are only three places to look: the row count of the table, the
summary of each column, and the step that combined them. Lesson 6 dealt with the first, a row count
that had gone stale. Sections 03 to 05 here are the second, and section 06 is the third, which is
the one that no amount of `ANALYZE` can fix on its own.
