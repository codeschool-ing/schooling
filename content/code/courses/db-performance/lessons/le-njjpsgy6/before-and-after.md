---
title: A change that looks right
version: 1
---

Every lesson in this course has ended with something faster. This one starts with a change that
looks just as sensible as the others, and asks the question the others took for granted: **was it
worth doing?** Not "did the query get faster" — it will — but whether what it gave back is more
than what it costs, measured rather than felt.

The candidate is the busiest statement in lesson 2's workload, a customer's list of their last ten
orders. Half of every hundred transactions are this one. Here is its plan as `market` stands:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=47.99..48.02 rows=10 width=29) (actual time=0.202..0.204 rows=10 loops=1)
   Buffers: shared hit=5 read=11
   ->  Sort  (cost=47.99..48.02 rows=11 width=29) (actual time=0.201..0.202 rows=10 loops=1)
         Sort Key: placed_at DESC
         Sort Method: quicksort  Memory: 25kB
         Buffers: shared hit=5 read=11
         ->  Bitmap Heap Scan on orders  (cost=4.51..47.80 rows=11 width=29) (actual time=0.066..0.151 rows=10 loops=1)
               Recheck Cond: (customer_id = 4242)
               Heap Blocks: exact=10
               Buffers: shared hit=2 read=11
               ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.043..0.043 rows=10 loops=1)
                     Index Cond: (customer_id = 4242)
                     Buffers: shared read=3
 Planning:
   Buffers: shared hit=137 read=4
 Planning Time: 1.001 ms
 Execution Time: 0.261 ms
(17 rows)

Time: 2.704 ms
```

The server finds the customer's orders through `orders_customer_id_idx`, fetches the ten rows, and
**sorts them** by `placed_at` to pick the newest ten. An index on `(customer_id, placed_at DESC)`
would hand the rows over already in that order, so the sort disappears and the scan stops at the
tenth row. That is textbook advice, and lesson 10 would say the same. It is exactly the kind of
change that gets made on a Friday afternoon because it is obviously right.

## Measure the before, three times

One run of anything is noise (lesson 1 section 06). So the before is three runs of the whole
workload, thirty seconds each, cut down to the two scripts that matter — the one the change is for,
and the one that writes to `orders` and will pay for any new index:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1148.472551 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17352 transactions (50.1% of total, tps = 575.862443)
 - latency average = 0.857 ms
 - latency stddev = 1.991 ms
SQL script 4: place-order.sql
 - 3541 transactions (10.2% of total, tps = 117.515497)
 - latency average = 8.251 ms
 - latency stddev = 5.825 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1134.043452 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17249 transactions (50.4% of total, tps = 571.828681)
 - latency average = 0.842 ms
 - latency stddev = 1.953 ms
SQL script 4: place-order.sql
 - 3501 transactions (10.2% of total, tps = 116.063088)
 - latency average = 8.794 ms
 - latency stddev = 8.038 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1151.505363 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17324 transactions (50.1% of total, tps = 577.402498)
 - latency average = 0.836 ms
 - latency stddev = 1.965 ms
SQL script 4: place-order.sql
 - 3494 transactions (10.1% of total, tps = 116.453725)
 - latency average = 8.156 ms
 - latency stddev = 5.331 ms
```

And the server's own view of the statement over those ninety seconds, before the tally is reset:

```
market=# SELECT calls, round(mean_exec_time::numeric, 3) AS mean_ms, round(total_exec_time) AS total_ms FROM pg_stat_statements WHERE query LIKE 'SELECT id, placed_at%';
 calls | mean_ms | total_ms 
-------+---------+----------
 51928 |   0.107 |     5578
(1 row)

Time: 2.461 ms

market=# SELECT pg_stat_statements_reset();
 pg_stat_statements_reset 
--------------------------
 
(1 row)

Time: 1.172 ms
```

## Make the change, and measure the after the same way

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at DESC);
CREATE INDEX
Time: 1186.757 ms (00:01.187)

market=# SELECT pg_size_pretty(pg_relation_size('orders_customer_placed_idx')) AS new_index, pg_size_pretty(pg_relation_size('orders_customer_id_idx')) AS old_index;
 new_index | old_index 
-----------+-----------
 60 MB     | 18 MB
(1 row)

Time: 0.887 ms
```

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..44.24 rows=10 width=29) (actual time=0.058..0.170 rows=10 loops=1)
   Buffers: shared hit=9 read=4
   ->  Index Scan using orders_customer_placed_idx on orders  (cost=0.43..48.62 rows=11 width=29) (actual time=0.057..0.167 rows=10 loops=1)
         Index Cond: (customer_id = 4242)
         Buffers: shared hit=9 read=4
 Planning:
   Buffers: shared hit=135 read=22
 Planning Time: 0.778 ms
 Execution Time: 0.194 ms
(9 rows)

Time: 2.448 ms
```

The plan is what the textbook promised: one `Index Scan using orders_customer_placed_idx`, no
`Sort`, and the scan stopped at ten rows. Execution went from 0.261 to **0.194 milliseconds**, and the
buffers from 16 touched to 13. Then the same three runs:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1200.249639 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17917 transactions (49.7% of total, tps = 596.976176)
 - latency average = 0.796 ms
 - latency stddev = 1.858 ms
SQL script 4: place-order.sql
 - 3636 transactions (10.1% of total, tps = 121.147814)
 - latency average = 8.357 ms
 - latency stddev = 5.404 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1116.698771 (without initial connection time)
SQL script 1: customer-orders.sql
 - 16837 transactions (50.2% of total, tps = 561.132217)
 - latency average = 0.794 ms
 - latency stddev = 1.882 ms
SQL script 4: place-order.sql
 - 3386 transactions (10.1% of total, tps = 112.846332)
 - latency average = 8.332 ms
 - latency stddev = 5.453 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1150.977750 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17420 transactions (50.4% of total, tps = 580.369711)
 - latency average = 0.800 ms
 - latency stddev = 1.930 ms
SQL script 4: place-order.sql
 - 3485 transactions (10.1% of total, tps = 116.107258)
 - latency average = 8.212 ms
 - latency stddev = 5.261 ms
```

```
market=# SELECT calls, round(mean_exec_time::numeric, 3) AS mean_ms, round(total_exec_time) AS total_ms FROM pg_stat_statements WHERE query LIKE 'SELECT id, placed_at%';
 calls | mean_ms | total_ms 
-------+---------+----------
 52176 |   0.089 |     4632
(1 row)

Time: 1.903 ms
```

## What the numbers say, before deciding what they mean

| | before | after |
|---|---|---|
| server's mean for the statement | 0.107 ms | 0.089 ms |
| pgbench latency, customer-orders, three runs | 0.857, 0.842, 0.836 ms | 0.796, 0.794, 0.800 ms |
| pgbench latency, place-order, three runs | 8.251, 8.794, 8.156 ms | 8.357, 8.332, 8.212 ms |
| overall rate, three runs | 1148, 1134, 1151 | 1200, 1116, 1150 |

The statement got faster: by the server's count, **0.018 milliseconds a call**, about a sixth. Every
other line of the table is the question of whether that is a real difference and what it cost —
which is the next two sections.
