---
title: The most common values
version: 1
---

Seller 1, the marketplace's own store, has a quarter of all orders. The other 999 sellers share the
rest, about 1500 each. A planner that only knew "1000 different sellers" would expect 2000 orders
for any of them and be wrong by a factor of 250 for the one that matters most. It is not wrong,
because the summary carries a second piece of information: **the values it saw most often, with
the share of the rows each one was**.

## Reading the list

`\x on` lays each column of the answer out on a line of its own, which is the only way two long
arrays fit on a screen:

```
market=# \x on
Expanded display is on.

market=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'seller_id';
-[ RECORD 1 ]-----+------------------------------------------------------------------------------------------------------
most_common_vals  | {1,553,391,831,295,379,520,561,377,706}
most_common_freqs | {0.2508,0.0013666666,0.0012666667,0.0012333334,0.0012,0.0012,0.0012,0.0012,0.0011666666,0.0011666666}

Time: 3.346 ms
```

Two arrays of the same length, read in pairs. Value **1** was **0.2508** of the sample, a quarter,
as `market.sql` made it. The next nine values are sellers that each happened to be about 0.0012 of
the sample: 41 rows or so out of 30,000. Ten entries in all, where the setting from section 02
allows up to a hundred, because `ANALYZE` only keeps a value that appeared clearly more often than
the average one. Seller 1 does by miles; the nine after it barely clear the bar, and that is worth
remembering for the third estimate below.

## Three estimates, worked by hand

Turn it off again with `\x off` and ask the planner about three sellers. `EXPLAIN` without
`ANALYZE` plans the query and stops, so the `rows=` it prints is the estimate and nothing else:

```
market=# EXPLAIN SELECT * FROM orders WHERE seller_id = 1;
                                        QUERY PLAN                                         
-------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=5647.83..28584.83 rows=501600 width=37)
   Recheck Cond: (seller_id = 1)
   ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..5522.43 rows=501600 width=0)
         Index Cond: (seller_id = 1)
(4 rows)

Time: 1.079 ms

market=# EXPLAIN SELECT * FROM orders WHERE seller_id = 42;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=19.98..4496.66 rows=1491 width=37)
   Recheck Cond: (seller_id = 42)
   ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0)
         Index Cond: (seller_id = 42)
(4 rows)

Time: 0.443 ms

market=# EXPLAIN SELECT * FROM orders WHERE seller_id = 553;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=33.61..7221.63 rows=2733 width=37)
   Recheck Cond: (seller_id = 553)
   ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..32.93 rows=2733 width=0)
         Index Cond: (seller_id = 553)
(4 rows)

Time: 0.418 ms
```

And the truth, counted:

```
market=# SELECT seller_id, count(*) FROM orders WHERE seller_id IN (1, 42, 553) GROUP BY seller_id ORDER BY seller_id;
 seller_id | count  
-----------+--------
         1 | 500114
        42 |   1532
       553 |   1590
(3 rows)

Time: 31.419 ms
```

**Seller 1: 501,600 estimated, 500,114 counted.** A value on the list is the easy case. Its
frequency times the row count of the table is the estimate: 0.2508 × 2,000,000 = 501,600, exactly
the number on the plan. Three tenths of a percent away from the truth.

**Seller 42: 1491 estimated, 1532 counted.** Seller 42 is not on the list, so the planner reasons
about what is left. The ten listed values add up to 0.2618 of the rows, which leaves 0.7382 for
everybody else. There are 1000 distinct sellers, ten of them listed, so 990 share that remainder,
and the planner assumes they share it **evenly**: 0.7382 ÷ 990 × 2,000,000 = **1491**, again the
number on the plan. Three percent off, because the 990 really are about even, which is how
`market.sql` drew them.

**Seller 553: 2733 estimated, 1590 counted.** This is the surprise. Seller 553 is second on the
list, at 0.0013666666, so its estimate is that frequency times two million. But 553 is an ordinary
seller with 1590 orders, no more than seller 42. It got on the list because the sample happened to
catch 41 of its rows instead of the 24 its real share would give, and once on the list, the luck of
the sample is taken as fact. **Being on the list made its estimate worse, not better**: 72% too
high, where seller 42, left to the average, was 3% too low.

That is the trade the list makes. For a value that is truly common, the list is the only thing that
keeps the estimate sane, and the skewed seller here is the reason it exists. For values that are
only common by the sample's chance, the list records noise. A bigger sample shrinks the noise, which
is what section 05 does with `SET STATISTICS`.

## Where the skew bites

The difference between seller 1 and seller 42 is not cosmetic. Both plans above are bitmap scans
on the index from lesson 2, but the cost the planner puts on them is **28,585 against 4,497**,
because it knows one fetches half a million rows and the other fifteen hundred. Lesson 4 showed the
choice between scans turning on exactly that number, and inside a bigger query the same number
decides the join, the order of the joins and whether a sort fits in memory. With a good list, the
same statement can get different plans for different sellers, which is right. With no list, or a
wrong one, every seller gets the plan for an average seller.

This also explains a trap from lesson 2. `pg_stat_statements` stores the seller dashboard as one
statement with one mean, whichever seller each run was about. The planner, by contrast, sees the
value when it plans an ordinary query, so it plans seller 1's dashboard and seller 42's
differently. The tally hides the very difference the planner is using.

## A column with no long tail

Every value of `status` fits on the list:

```
market=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';
           most_common_vals            |           most_common_freqs           
---------------------------------------+---------------------------------------
 {delivered,cancelled,shipped,pending} | {0.9469333,0.0284,0.021366667,0.0033}
(1 row)

Time: 4.671 ms

market=# SELECT status, count(*) FROM orders GROUP BY status ORDER BY count(*) DESC;
  status   |  count  
-----------+---------
 delivered | 1890887
 cancelled |   58372
 shipped   |   43422
 pending   |    7319
(4 rows)

Time: 121.674 ms
```

Four values, four entries, nothing left over for an average. The estimate for any of them is its
frequency times two million. So `pending` is estimated at 0.0033 × 2,000,000 = 6600 rows and there
are **7319**: 10% under, because the sample of 30,000 saw 99 pending orders where the table's share
would give 110. Small numbers in a sample move by a lot in proportion.

The more important line is the last: `pending` is **0.37% of the table**. A condition that picks
under half a percent of two million rows is exactly the kind an index answers well, and lesson 9
builds a much smaller index than the obvious one for it.
