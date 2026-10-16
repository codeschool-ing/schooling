---
title: What a wider index costs
version: 1
---

A covering index is faster for the query it covers and more expensive for everything else. The
expense is easy to miss, because it does not show up in the query you were looking at. It shows up
on disk, and in every write to the table.

## On disk

```
market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders', 'orders_customer_id_idx', 'orders_customer_placed_idx');
          relname           |  size  
----------------------------+--------
 orders_customer_id_idx     | 18 MB
 orders                     | 133 MB
 orders_customer_placed_idx | 112 MB
(3 rows)

Time: 2.544 ms
```

**112 MB for the covering index, 18 MB for the one on `customer_id` alone**: six times the size, and
almost as big as the 133 MB table it indexes. It holds five columns for each of two million orders,
and a covering index is a partial copy of its table by design. Every extra column in `INCLUDE` is
another slice of the table copied into the index.

That size has a cost beyond disk. The index competes with the table for the 128 MB of shared buffers
lesson 1 measured, and the query that runs most is the one whose index pages stay in memory; an index
six times bigger keeps six times as many pages warm, or fails to.

## On every write

Each index on a table is updated on every insert, and on every update that cannot be made in place.
The second clause matters here, and it needs one more piece of how PostgreSQL updates rows.

When an `UPDATE` changes no column that any index holds, and the new version fits on the same page,
PostgreSQL can write a **HOT update**, heap-only tuple: the new version goes on the same page,
chained from the old one, and **no index is touched at all**. When the update changes an indexed
column, every index on the table gets a new entry.

`place-order.sql` from lesson 2 inserts an order with `total_cents = 0` and then updates
`total_cents` with the real sum. Run it for fifteen seconds without the covering index, then with
it, and count the updates that were HOT:

```
market=# DROP INDEX orders_customer_placed_idx;
DROP INDEX
Time: 133.094 ms

market=# SELECT pg_stat_reset_single_table_counters('orders'::regclass);
 pg_stat_reset_single_table_counters 
-------------------------------------
 
(1 row)

Time: 0.968 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f place-order.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 2.443 ms
tps = 3274.924436 (without initial connection time)
market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     49119 |         49051
(1 row)

Time: 8.344 ms
```

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (id, status, total_cents);
CREATE INDEX
Time: 1997.432 ms (00:01.997)

market=# SELECT pg_stat_reset_single_table_counters('orders'::regclass);
 pg_stat_reset_single_table_counters 
-------------------------------------
 
(1 row)

Time: 0.809 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f place-order.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 2.311 ms
tps = 3460.963785 (without initial connection time)
market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     51946 |             0
(1 row)

Time: 4.678 ms
```

**Without the covering index, 49,051 of 49,119 updates were HOT.** `total_cents` was in no index,
so almost every update stayed on its page and touched no index. **With it, 0 of 51,946.** The index
`INCLUDE`s `total_cents`, so changing it is changing an indexed value, and every update now writes a
new row version somewhere else and a new entry in **every** index on `orders`: the primary key,
`customer_id`, `placed_at`, `seller_id` and the covering one.

And yet the throughput did not drop: **3275 transactions a second without, 3461 with**. That is the
honest result of this measurement and it is worth not explaining away. Fifteen seconds of a small
transaction on a machine with spare memory does not show the cost; the difference between the two
runs is inside the noise lesson 1 warned about. What the run does show is the mechanism, in a
counter that does not depend on timing: every update now leaves a dead row version and five index
entries behind for `VACUUM` to clean, where before it left almost nothing. On a busy table that is
more `VACUUM` work, more bloat between vacuums, and section 03's cleared visibility bits on more
pages. Lesson 11 is about that write tax, measured on its own.

## Deciding

A covering index is worth it when the query it covers is **frequent**, and when the columns it
carries are **rarely updated**. `customer-orders.sql` is the most frequent query in lesson 2's
workload, which argues for it. `total_cents` is updated right after every insert, which argues
against including it.

So here the better choice may be the index without `total_cents`: key `(customer_id,
placed_at)`, `INCLUDE (id, status)`. It still finds the ten orders and hands them over in order, with
no sort, and reads ten table pages for `total_cents`, and an update of `total_cents` can be HOT again. The other way out is to
change the application to write the total in the `INSERT` instead of updating it afterwards. Each
choice trades something. The point of this section is that the trade has two sides, and the timing
of the query you fixed is only one of them.

This lesson changed rows and built an index on `market`. Close `psql` and put the database back as
lesson 3 starts:

```sh
~/reset-market.sh
```
