---
title: The first fix, and the way back
version: 1
---

The tally named three statements. Two of them need tools later lessons teach: the tag search wants
an index type that understands arrays (lesson 8), and the pending count wants an index on a small
part of a table (lesson 9). The third one can be fixed today, with what lesson 1 showed you.

The seller dashboard asks for one seller's December orders. `orders` has an index on `placed_at`,
so the server can find December quickly:

```
market=# SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
 count  
--------
 107780
(1 row)

Time: 9.945 ms
```

But then it has to look at each of those 107780 orders to keep the twenty-nine that belong to this
seller. There is no index on
`seller_id`. Lesson 1 section 05 built one and dropped it again; this time the tally said it is
needed, which is the right reason to build it.

## Fix one thing, then measure the same way

Reset the tally, so that the next numbers count from zero, build the index, and run the same
workload for the same minute:

```
market=# SELECT pg_stat_statements_reset();
 pg_stat_statements_reset 
--------------------------
 
(1 row)

Time: 1.787 ms

market=# CREATE INDEX orders_seller_id_idx ON orders (seller_id);
CREATE INDEX
Time: 1221.753 ms (00:01.222)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 20.0 s, 994.0 tps, lat 8.030 ms stddev 26.556, 0 failed
progress: 40.0 s, 913.0 tps, lat 8.771 ms stddev 30.397, 0 failed
progress: 60.0 s, 1013.4 tps, lat 7.889 ms stddev 26.561, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 58416
number of failed transactions: 0 (0.000%)
latency average = 8.218 ms
latency stddev = 27.827 ms
initial connection time = 8.056 ms
tps = 972.682647 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 29131 transactions (49.9% of total, tps = 485.059199)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.975 ms
 - latency stddev = 2.153 ms
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 14585 transactions (25.0% of total, tps = 242.854293)
 - number of failed transactions: 0 (0.000%)
 - latency average = 1.065 ms
 - latency stddev = 2.118 ms
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 5926 transactions (10.1% of total, tps = 98.673606)
 - number of failed transactions: 0 (0.000%)
 - latency average = 34.316 ms
 - latency stddev = 13.558 ms
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 5721 transactions (9.8% of total, tps = 95.260159)
 - number of failed transactions: 0 (0.000%)
 - latency average = 9.738 ms
 - latency stddev = 6.880 ms
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 2458 transactions (4.2% of total, tps = 40.928067)
 - number of failed transactions: 0 (0.000%)
 - latency average = 12.498 ms
 - latency stddev = 6.868 ms
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 591 transactions (1.0% of total, tps = 9.840719)
 - number of failed transactions: 0 (0.000%)
 - latency average = 247.697 ms
 - latency stddev = 74.672 ms
market=# SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms, round(100 * total_exec_time / sum(total_exec_time) OVER ()) AS pct, left(regexp_replace(query, '\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY total_exec_time DESC LIMIT 8;
 calls | total_ms | mean_ms | pct |                       query                        
-------+----------+---------+-----+----------------------------------------------------
  5926 |   196013 |   33.08 |  52 | SELECT id, title, price_cents FROM products WHERE 
   591 |   145822 |  246.74 |  39 | SELECT count(*) FROM orders WHERE status = $1
  2458 |    27667 |   11.26 |   7 | SELECT date_trunc($1, placed_at) AS day, count(*),
 29132 |     3344 |    0.11 |   1 | SELECT id, placed_at, status, total_cents FROM ord
 14585 |     1448 |    0.10 |   0 | SELECT p.title, l.quantity, l.price_cents FROM ord
  5724 |     1418 |    0.25 |   0 | INSERT INTO orders (customer_id, seller_id, placed
     1 |     1211 | 1210.89 |   0 | CREATE INDEX orders_seller_id_idx ON orders (selle
  5724 |      696 |    0.12 |   0 | INSERT INTO order_lines (order_id, line, product_i
(8 rows)

Time: 3.428 ms
```

Compare the seller dashboard's row with the one before the fix:

| | before | after |
|---|---|---|
| mean per run | 35.49 ms | 11.26 ms |
| total in one minute | 76810 ms | 27667 ms |
| share of the server | 21% | 7% |
| pgbench's latency for the script | 36.674 ms | 12.498 ms |

**About a third of the time per run, and two thirds of its share of the server given back.** The
measurement was taken the same way both times — same workload, same minute, same machine, tally
reset before each — which is what makes the two columns comparable. Change two things at once, or
measure the after differently from the before, and the table means nothing.

Notice what did not change. The tag search and the pending count are still at the top, larger now
in share because the total shrank around them. And the overall rate barely moved, from 912 to 972
transactions a second: the seller dashboard is four in every hundred transactions, so a large
improvement to it is a small improvement to the whole. Lesson 24 is about telling those two apart
before you spend a week on the wrong one.

The index cost something too: **1221 milliseconds to build**, and every order written from now on
pays a little to keep it current. The `place-order.sql` script is in the workload so that this cost
shows up, and lesson 11 is where it gets measured.

## Back to the known rows

The workload wrote orders. Every run of `place-order.sql` added one, so `market` now holds several
thousand orders that `market.sql` never made, and the counts in the next lessons' transcripts would
stop matching yours. Lesson 1 kept a copy of the database as it was loaded; this script puts
`market` back as that copy and adds the two things this lesson built, the extension and the index:


```sh
cat > ~/reset-market.sh <<'SH'
#!/bin/sh
# Put market back as lesson 3 starts: the rows market.sql made, plus
# lesson 2's extension and index. Close every psql on market first.
set -e
dropdb --if-exists market
createdb -T market_base market
psql -q market -c 'CREATE EXTENSION pg_stat_statements' \
               -c 'CREATE INDEX orders_seller_id_idx ON orders (seller_id)'
SH
chmod +x ~/reset-market.sh
```

Run it whenever your numbers drift from the transcripts, and whenever a lesson tells you to. It
needs every `psql` connected to `market` closed first, because a database cannot be dropped while
somebody is in it:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 10.039 ms
CREATE INDEX
Time: 1429.029 ms (00:01.429)
market=# SELECT count(*) FROM orders;
  count  
---------
 2000000
(1 row)

Time: 66.883 ms

market=# \di orders*
                    List of relations
 Schema |          Name          | Type  | Owner | Table  
--------+------------------------+-------+-------+--------
 public | orders_customer_id_idx | index | ana   | orders
 public | orders_pkey            | index | ana   | orders
 public | orders_placed_at_idx   | index | ana   | orders
 public | orders_seller_id_idx   | index | ana   | orders
(4 rows)
EXIT 0
```

Two million orders again, and the four indexes every lesson from 3 on starts with. The `Time:`
lines come from `~/.psqlrc`, which `psql` reads even when it runs a single command.
