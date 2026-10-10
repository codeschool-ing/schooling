---
title: Finding the ones nobody reads
version: 1
---

The server counts, for every index, how many times a query has started a scan of it. The count is
in `pg_stat_user_indexes.idx_scan`, and an index whose count stays at zero while the application
runs is an index nobody reads. **That sentence is the whole method, and almost every way of
getting it wrong is a mistake about the period the counter covers.** This section reads the
counter after a realistic minute, and then goes through the four reasons a zero can lie.

## A minute of the real workload

The counters cover everything since they were last cleared, which on `market` includes the two
pgbench runs of the previous section. Clear them, and run lesson 2's whole mix for a minute, the
same command lesson 2 used:

```
market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.992 ms
```

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 20.0 s, 2464.3 tps, lat 3.242 ms stddev 6.756, 0 failed
progress: 40.0 s, 2410.9 tps, lat 3.318 ms stddev 6.985, 0 failed
progress: 60.0 s, 2384.7 tps, lat 3.353 ms stddev 7.093, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 145211
number of failed transactions: 0 (0.000%)
latency average = 3.305 ms
latency stddev = 6.945 ms
initial connection time = 8.505 ms
tps = 2419.598234 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 72683 transactions (50.1% of total, tps = 1211.090471)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.545 ms
 - latency stddev = 1.118 ms
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 36337 transactions (25.0% of total, tps = 605.470254)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.605 ms
 - latency stddev = 1.126 ms
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 14456 transactions (10.0% of total, tps = 240.875086)
 - number of failed transactions: 0 (0.000%)
 - latency average = 21.895 ms
 - latency stddev = 6.219 ms
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 14503 transactions (10.0% of total, tps = 241.658230)
 - number of failed transactions: 0 (0.000%)
 - latency average = 5.144 ms
 - latency stddev = 3.333 ms
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 5750 transactions (4.0% of total, tps = 95.810165)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.907 ms
 - latency stddev = 1.206 ms
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 1475 transactions (1.0% of total, tps = 24.577390)
 - number of failed transactions: 0 (0.000%)
 - latency average = 14.932 ms
 - latency stddev = 5.515 ms
```

(pgbench went on to print a breakdown per script, left out here.) Now read every index's count,
lowest first:

```
market=# SELECT relname AS table, indexrelname AS index, idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_stat_user_indexes ORDER BY idx_scan, relname, indexrelname;
    table    |            index            | idx_scan |  size   
-------------+-----------------------------+----------+---------
 customers   | customers_email_key         |        0 | 14 MB
 events      | events_pkey                 |        0 | 107 MB
 order_lines | order_lines_pkey            |        0 | 152 MB
 order_lines | order_lines_product_id_idx  |        0 | 33 MB
 orders      | orders_customer_id_idx      |        0 | 18 MB
 orders      | orders_placed_at_idx        |        0 | 44 MB
 orders      | orders_placed_at_status_idx |        0 | 79 MB
 orders      | orders_seller_id_idx        |        0 | 14 MB
 orders      | orders_total_cents_idx      |        0 | 14 MB
 orders      | orders_status_idx           |     1475 | 14 MB
 orders      | orders_seller_placed_idx    |     5750 | 69 MB
 customers   | customers_pkey              |    29010 | 4408 kB
 orders      | orders_pkey                 |    29010 | 45 MB
 sellers     | sellers_pkey                |    29010 | 40 kB
 order_lines | order_lines_order_id_idx    |    50844 | 78 MB
 order_lines | order_lines_product_id_idx1 |    72678 | 33 MB
 orders      | orders_customer_idx         |    72686 | 18 MB
 products    | products_pkey               |   192376 | 1112 kB
(18 rows)

Time: 6.663 ms
```

Eighteen indexes, and **nine of them were not read once in 145,211 transactions.** Before
dropping anything, look at what the list actually says, because it is more interesting than nine
zeros.

**The duplicates split the reads.** `orders_customer_idx`, added in 2023 for the support search,
took 72,686 scans, and `orders_customer_id_idx`, the one the database was born with, took none.
The planner saw two identical indexes and picked one, and the counter faithfully records that it
never needed the other. The same happened to `order_lines_product_id_idx1`. Read naively, the list
says to drop the originals; read correctly, it says one of each pair is spare, and section 04 of
this lesson decides which.

**A primary key with no reads.** `order_lines_pkey` shows zero, because the order page asks for
`WHERE order_id = …` and the planner preferred the smaller single-column `order_lines_order_id_idx`
for that, 50,844 times. The primary key is still doing its other job: refusing a second line with
the same `(order_id, line)`. That job leaves no trace in `idx_scan`.

**Some reads come from the server itself.** `sellers_pkey` and `customers_pkey` were scanned
29,010 times each, by nobody in the workload: no script looks up a seller by id. Every order
inserted has to prove that its `seller_id` and `customer_id` exist, and those foreign-key checks
are index scans. The same number on `orders_pkey` is the `UPDATE … WHERE id = :order_id` in
`place-order.sql`.

## Since when

A zero means nothing without the moment counting began. PostgreSQL keeps it per database:

```
market=# SELECT stats_reset FROM pg_stat_database WHERE datname = 'market';
          stats_reset          
-------------------------------
 2026-10-10 04:50:09.488338-03
(1 row)

Time: 3.293 ms

market=# SELECT indexrelname AS index, idx_scan, last_idx_scan FROM pg_stat_user_indexes WHERE relname = 'orders' ORDER BY indexrelname;
            index            | idx_scan |         last_idx_scan         
-----------------------------+----------+-------------------------------
 orders_customer_id_idx      |        0 | 
 orders_customer_idx         |    72686 | 2026-10-10 04:51:09.932455-03
 orders_pkey                 |    29010 | 2026-10-10 04:51:09.932455-03
 orders_placed_at_idx        |        0 | 
 orders_placed_at_status_idx |        0 | 
 orders_seller_id_idx        |        0 | 
 orders_seller_placed_idx    |     5750 | 2026-10-10 04:51:09.932455-03
 orders_status_idx           |     1475 | 2026-10-10 04:51:09.932455-03
 orders_total_cents_idx      |        0 | 
(9 rows)

Time: 4.702 ms
```

The counters started at 04:50:09 and the last scan of anything on `orders` was at 04:51:09, the
end of the one-minute run. `last_idx_scan` is new in PostgreSQL 16, and it is the column to read
on a real server, because **a scan last week and no scan in a year look the same in `idx_scan`
but not in `last_idx_scan`**.

## The query to keep

This file lists the indexes with no reads since the reset, largest first, and leaves out unique
ones for the reason `order_lines_pkey` showed: a unique index enforces a rule even when no query
reads it, and dropping it drops the rule. Save it and run it:

```sh
cat > ~/unused-indexes.sql <<'SQL'
-- unused-indexes.sql: indexes no query has read since the counters
-- were last reset, biggest first. Unique ones are left out: they
-- enforce a rule even when nobody reads them.
SELECT s.relname AS table,
       s.indexrelname AS index,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS size
FROM pg_stat_user_indexes AS s
JOIN pg_index AS i USING (indexrelid)
WHERE s.idx_scan = 0 AND NOT i.indisunique
ORDER BY pg_relation_size(s.indexrelid) DESC;
SQL
```

```
ana@vm:~$ psql market -f unused-indexes.sql
    table    |            index            | size  
-------------+-----------------------------+-------
 orders      | orders_placed_at_status_idx | 79 MB
 orders      | orders_placed_at_idx        | 44 MB
 order_lines | order_lines_product_id_idx  | 33 MB
 orders      | orders_customer_id_idx      | 18 MB
 orders      | orders_total_cents_idx      | 14 MB
 orders      | orders_seller_id_idx        | 14 MB
(6 rows)

Time: 3.996 ms
```

Six candidates and 202 MB. **A candidate, not a verdict**, and here are the four reasons.

## Four ways a zero lies

**The window was too short.** The leftovers file says `orders_placed_at_status_idx` was built in
2024 for the monthly report, and a minute of daytime traffic never runs a monthly report. Run it
once:

```
market=# SELECT status, count(*) FROM orders WHERE placed_at >= '2025-11-01' AND placed_at < '2025-12-01' GROUP BY status;
  status   | count  
-----------+--------
 cancelled |   3108
 delivered | 102395
(2 rows)

Time: 34.511 ms
```

```
market=# SELECT indexrelname AS index, idx_scan FROM pg_stat_user_indexes WHERE indexrelname LIKE 'orders_placed_at%';
            index            | idx_scan 
-----------------------------+----------
 orders_placed_at_idx        |        1
 orders_placed_at_status_idx |        0
(2 rows)

Time: 3.398 ms
```

One scan, and of `orders_placed_at_idx`, the index the database was born with, not of the one
built for the report. That is a finding in itself, and section 05 of this lesson uses it. But the
general rule is the one to keep: **the counter has to have covered every cycle the application
has** — the nightly job, the month-end close, the yearly audit. On a real server that means
reading `stats_reset` and waiting until it is older than the longest of those, or asking the people
who run the reports.

**The counters were reset.** `pg_stat_reset()` is one call, and anybody with the right to run it
may have, for their own measurement. The counters also start from zero after a crash or an
immediate shutdown, though a clean restart keeps them. `stats_reset` is the date to read before
believing any zero.

**The reads happen on another server.** The counters are per server. An application that sends
its reports to a read replica (lesson 20) reads indexes there, and the primary, which is where you
are tempted to drop them, counts nothing. Read `pg_stat_user_indexes` on every replica too: the
index is the same file everywhere, so dropping it on the primary drops it from all of them.

**The index exists for a rule, not for reads.** The query above leaves out unique indexes, but a
non-unique index can still matter without reads: an exclusion constraint is backed by one, and
deleting from a parent table needs an index on the child's foreign key to avoid reading the whole
child table, which happens rarely and shows as a scan only on the day it is needed. Before dropping
an index on a referencing column, ask whether its parent rows are ever deleted.

None of these makes the counter useless. They make it **the first question and not the last**:
zero over a long enough window, on every server, for an index that enforces nothing, is as close
to proof as a database gives you.
