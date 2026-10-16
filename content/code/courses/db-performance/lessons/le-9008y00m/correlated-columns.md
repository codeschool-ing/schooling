---
title: Two columns that say one thing
version: 1
---

Everything so far was about one column at a time, and every one of those summaries was good. This
section is about a plan that goes wrong although each column's summary is right, because the
mistake is in the step that combines them.

## The independence assumption

A `WHERE` clause with two conditions gets two selectivities, one per column, and the planner
**multiplies** them. That is correct when the columns have nothing to do with each other: if half
the customers have a name starting with a vowel and a tenth live in Recife, about a twentieth are
both. It is wrong when one column predicts the other, and `market.sql` made `city` and `state`
exactly that: a customer's city always comes with the same state.

Here is what the summary knows about Curitiba and about Paraná, and what the planner makes of both
together:

```
market=# SELECT attname, (most_common_vals::text::text[])[5] AS value, most_common_freqs[5] AS freq FROM pg_stats WHERE tablename = 'customers' AND attname = 'city';
 attname |  value   |  freq  
---------+----------+--------
 city    | Curitiba | 0.0685
(1 row)

Time: 3.626 ms

market=# SELECT attname, (most_common_vals::text::text[])[4] AS value, most_common_freqs[4] AS freq FROM pg_stats WHERE tablename = 'customers' AND attname = 'state';
 attname | value |  freq  
---------+-------+--------
 state   | PR    | 0.0685
(1 row)

Time: 1.391 ms

market=# EXPLAIN SELECT * FROM customers WHERE city = 'Curitiba' AND state = 'PR';
                                  QUERY PLAN                                  
------------------------------------------------------------------------------
 Gather  (cost=1000.00..5141.51 rows=938 width=59)
   Workers Planned: 1
   ->  Parallel Seq Scan on customers  (cost=0.00..4047.71 rows=552 width=59)
         Filter: ((city = 'Curitiba'::text) AND (state = 'PR'::text))
(4 rows)

Time: 1.072 ms

market=# SELECT count(*) FROM customers WHERE city = 'Curitiba' AND state = 'PR';
 count 
-------
 13578
(1 row)

Time: 19.107 ms
```

Each half is right. Curitiba is **0.0685** of the customers, and so is PR, because Curitiba is the
only city in Paraná here. But the plan expects **938** customers, 0.0685 × 0.0685 × 200,000, as if
knowing the city told you nothing about the state. There are **13,578**: the estimate is fourteen
times too small, and nothing about it would improve with a bigger sample, since both fractions are
already right.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two squares, each standing for the 200,000 customers. In the left one, what the planner assumes: a narrow vertical strip for city Curitiba, 6.85% of the customers, and a narrow horizontal strip for state PR, also 6.85%, crossing in a tiny square of 0.47%, which is 938 customers. In the right one, what the table holds: the whole Curitiba strip is PR, so the overlap is the full strip, 13,578 customers.\"><text x=\"160.0\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">what the planner assumes</text><rect x=\"60\" y=\"44\" width=\"200\" height=\"200\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520.0\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">what the table holds</text><rect x=\"420\" y=\"44\" width=\"200\" height=\"200\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"44\" width=\"13.7\" height=\"200\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"60\" y=\"164\" width=\"200\" height=\"13.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"164\" width=\"13.7\" height=\"13.7\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"139.7\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">city = Curitiba, 6.85%</text><text x=\"266\" y=\"170.85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">state = PR,</text><text x=\"266\" y=\"184.85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6.85%</text><path d=\"M133.7 177.7 L160.0 268\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"164\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">0.47%: 938 rows</text><rect x=\"480\" y=\"44\" width=\"13.7\" height=\"200\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"499.7\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Curitiba, all of it PR</text><path d=\"M493.7 200 L520.0 268\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"524\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">6.85%: 13,578 rows</text></svg>", "caption": "The independence assumption, to scale. Multiplying two fractions is right when the columns are unrelated; for a city and its state it makes the overlap fourteen times too small."}
```

A count fourteen times too small is the kind of error lesson 6 followed up through a plan. A scan
the planner believes returns 938 rows is a good candidate for the inner side of a nested loop, and
at 13,578 rows that loop runs fourteen times longer than it was costed. Real schemas are full of
these pairs: a postcode and its city, a product and its category, a date and its fiscal quarter, a
column and another column computed from it.

## `CREATE STATISTICS`

The planner cannot discover a relation between two columns on its own, because `ANALYZE` looks at
one column at a time. You have to name the pair, and `CREATE STATISTICS` does that. It makes an
object that tells `ANALYZE` to also measure the two columns together:

```
market=# CREATE STATISTICS customers_city_state (dependencies, mcv) ON city, state FROM customers;
CREATE STATISTICS
Time: 2.461 ms

market=# ANALYZE customers;
ANALYZE
Time: 191.553 ms

market=# EXPLAIN SELECT * FROM customers WHERE city = 'Curitiba' AND state = 'PR';
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..5283.00 rows=13320 width=59)
   Filter: ((city = 'Curitiba'::text) AND (state = 'PR'::text))
(2 rows)

Time: 0.970 ms

market=# SELECT statistics_name, attnames, dependencies FROM pg_stats_ext WHERE tablename = 'customers';
   statistics_name    |   attnames   |               dependencies               
----------------------+--------------+------------------------------------------
 customers_city_state | {city,state} | {"4 => 5": 1.000000, "5 => 4": 0.421733}
(1 row)

Time: 3.503 ms
```

The same query, after one `ANALYZE`: **13,320** expected where there are 13,578, 2% apart. The plan
changed with it, from a parallel scan to a plain one: a different number of rows is a different set
of costs, and the cheapest plan moved.

The statement asks for two kinds of measurement in parentheses, and `pg_stats_ext` shows what they
found:

- **`dependencies`** measures how far one column determines the other. The numbers are the
  columns' positions in the table, so `4` is `city` and `5` is `state`. `"4 => 5": 1.000000`
  says that knowing the city fixes the state in every row of the sample; `"5 => 4": 0.421733` says
  the state fixes the city less than half of the time, because SP and RJ have several cities each.
  When both columns appear in a `WHERE` clause, the planner uses the dependency to stop multiplying.
- **`mcv`** keeps a list of the most common **pairs** of values, with their frequencies, the way
  section 03's list does for single values. For a pair on the list, the estimate is read from it directly
  instead of being multiplied out.

## The third kind: `ndistinct`

The objects above fix a `WHERE` clause. A `GROUP BY` over both columns needs something else:

```
market=# EXPLAIN SELECT city, state, count(*) FROM customers GROUP BY city, state;
                                            QUERY PLAN                                             
---------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=5346.56..5360.87 rows=108 width=21)
   Group Key: city, state
   ->  Gather Merge  (cost=5346.56..5358.98 rows=108 width=21)
         Workers Planned: 1
         ->  Sort  (cost=4346.55..4346.82 rows=108 width=21)
               Sort Key: city, state
               ->  Partial HashAggregate  (cost=4341.82..4342.90 rows=108 width=21)
                     Group Key: city, state
                     ->  Parallel Seq Scan on customers  (cost=0.00..3459.47 rows=117647 width=13)
(9 rows)

Time: 2.585 ms
```

**108 groups** expected: 12 cities times 9 states, every combination assumed possible. There are
twelve, one per city. Neither `dependencies` nor `mcv` is used to count groups, so the object needs
its third kind, `ndistinct`, which stores the number of distinct combinations. An object's kinds are
fixed when it is created, so it is dropped and made again with all three:

```
market=# DROP STATISTICS customers_city_state;
DROP STATISTICS
Time: 1.498 ms

market=# CREATE STATISTICS customers_city_state (ndistinct, dependencies, mcv) ON city, state FROM customers;
CREATE STATISTICS
Time: 1.335 ms

market=# ANALYZE customers;
ANALYZE
Time: 161.593 ms

market=# EXPLAIN SELECT city, state, count(*) FROM customers GROUP BY city, state;
                                            QUERY PLAN                                             
---------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=5342.17..5343.76 rows=12 width=21)
   Group Key: city, state
   ->  Gather Merge  (cost=5342.17..5343.55 rows=12 width=21)
         Workers Planned: 1
         ->  Sort  (cost=4342.16..4342.19 rows=12 width=21)
               Sort Key: city, state
               ->  Partial HashAggregate  (cost=4341.82..4341.94 rows=12 width=21)
                     Group Key: city, state
                     ->  Parallel Seq Scan on customers  (cost=0.00..3459.47 rows=117647 width=13)
(9 rows)

Time: 0.759 ms
```

**12 groups**, the right number. With no list of kinds at all, `CREATE STATISTICS` builds all three,
which is the usual way to write it; this lesson named them to show what each one does.

## What it costs, and when to bother

An extended statistics object costs some time at every `ANALYZE` of the table and a small row in
the catalogue, and it only helps queries that filter or group by those columns together. So it is
not something to create for every pair of columns. Create one when a plan shows a big gap between
estimated and actual rows on a condition over two columns, and the two columns are related by what
they mean. That is the situation lesson 6 taught you to spot, and this is its fix.

## Back to where lesson 3 starts

This lesson left three things behind on `market`: the target and the `n_distinct` setting on
`order_lines.order_id`, and the statistics object on `customers`. Close `psql` and put the database
back the way lesson 2 taught:

```sh
~/reset-market.sh
```
