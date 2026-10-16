---
title: Reading what pgbench reports
version: 1
---

A `pgbench` report is forty lines, and most people read one of them: `tps`. That number is real
and it is the least informative line in the report, because it says how much work was done and
nothing about how it felt to the people waiting for it. Two flags put the rest on the screen:
`-P 10` prints progress every ten seconds, and `-r` reports the latency of every statement in every
script. Lesson 2's workload, thirty seconds:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -P 10 -r -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 10.0 s, 1263.4 tps, lat 6.303 ms stddev 22.251, 0 failed
progress: 20.0 s, 1156.7 tps, lat 6.900 ms stddev 24.618, 0 failed
progress: 30.0 s, 1288.9 tps, lat 6.190 ms stddev 21.487, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 37131
number of failed transactions: 0 (0.000%)
latency average = 6.465 ms
latency stddev = 22.826 ms
initial connection time = 8.671 ms
tps = 1234.090860 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 18707 transactions (50.4% of total, tps = 621.748343)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.986 ms
 - latency stddev = 2.972 ms
 - statement latencies in milliseconds and failures:
         0.001           0  \set c random(1, 200000)
         0.984           0  SELECT id, placed_at, status, total_cents
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 9274 transactions (25.0% of total, tps = 308.231899)
 - number of failed transactions: 0 (0.000%)
 - latency average = 1.025 ms
 - latency stddev = 2.540 ms
 - statement latencies in milliseconds and failures:
         0.001           0  \set o random(1, 2000000)
         1.023           0  SELECT p.title, l.quantity, l.price_cents
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 3597 transactions (9.7% of total, tps = 119.550371)
 - number of failed transactions: 0 (0.000%)
 - latency average = 25.944 ms
 - latency stddev = 20.190 ms
 - statement latencies in milliseconds and failures:
         0.001           0  \set t random(1, 5)
        25.943           0  SELECT id, title, price_cents FROM products
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 3704 transactions (10.0% of total, tps = 123.106637)
 - number of failed transactions: 0 (0.000%)
 - latency average = 9.368 ms
 - latency stddev = 9.327 ms
 - statement latencies in milliseconds and failures:
         0.002           0  \set c random(1, 200000)
         0.001           0  \set s random(1, 1000)
         0.001           0  \set p random(1, 50000)
         0.829           0  BEGIN;
         0.474           0  INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)
         0.585           0  INSERT INTO order_lines (order_id, line, product_id, quantity, price_cents)
         0.540           0  UPDATE orders SET total_cents = (SELECT sum(quantity * price_cents)
         6.939           0  COMMIT;
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 1486 transactions (4.0% of total, tps = 49.388894)
 - number of failed transactions: 0 (0.000%)
 - latency average = 8.289 ms
 - latency stddev = 10.027 ms
 - statement latencies in milliseconds and failures:
         0.002           0  \set s random(2, 1000)
         8.287           0  SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents)
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 363 transactions (1.0% of total, tps = 12.064716)
 - number of failed transactions: 0 (0.000%)
 - latency average = 197.742 ms
 - latency stddev = 67.727 ms
 - statement latencies in milliseconds and failures:
       197.742           0  SELECT count(*) FROM orders WHERE status = 'pending';
```

Read it in four layers.

## The run as a whole

- **`number of transactions actually processed: 37131`** in **`duration: 30 s`**, and
  **`number of failed transactions: 0`**. Check the failures first: a run where transactions failed
  measured something other than your workload, however good its other numbers look.
- **`tps = 1234.090860 (without initial connection time)`** is the throughput: 37131 transactions
  over thirty seconds, with the 8.7 milliseconds spent opening the eight connections left out. A real
  application keeps its connections open, so leaving them out is right.
- **`latency average = 6.465 ms`** is the mean time from sending a transaction to its last answer.
  With eight clients each sending the next transaction the moment the last one returns, 8 divided by
  0.006465 seconds is about 1237 a second — the `tps` again, which is why in this mode the two numbers
  are one fact written twice.

## The spread

**`latency stddev = 22.826 ms`**: the standard deviation is **three and a half times the mean**.
That cannot happen with a spread that is symmetrical around 6.5 milliseconds, since no transaction
takes less than zero. It means most transactions are fast and a few are very slow, and the average
sits between two groups it describes badly. The per-script blocks below say who the two groups are.

The average and the standard deviation are the only summary `pgbench` prints, and for latency they
are the wrong summary. What a user feels is a percentile: the time that 95 or 99 transactions in a
hundred come in under. `pgbench -l` writes every transaction's latency to a log, and lesson 23 builds
a short script that reads those logs and prints the 50th, 95th and 99th percentiles; use it whenever
the standard deviation is larger than the mean, which on a mixed workload is almost always.

`pgbench` prints the standard deviation only when `-P` or a rate is in effect; the runs further on
that use neither show the average alone.

## The progress lines

`progress: 10.0 s, 1263.4 tps … progress: 20.0 s, 1156.7 tps … progress: 30.0 s, 1288.9 tps`. The
same run, ten seconds at a time, moved by about 10%. Nothing changed between the intervals except
what always changes — which rows were asked for, what else the computer was doing — and that is the
first sight of the noise the last section of this lesson measures. A run whose progress lines
**trend** instead of wobbling, steadily up or steadily down, has not settled, and its total is an
average of two different states.

## Per script, per statement

Each script gets a block: its weight and the share it really got, its own `tps`, and its own latency
average and standard deviation. Then `-r` adds a line per statement, with its average latency in
milliseconds and its failures:

| script | latency average | where the time goes |
|---|---|---|
| `customer-orders.sql` | 0.986 ms | the `SELECT`, 0.984 |
| `order-page.sql` | 1.025 ms | the `SELECT`, 1.023 |
| `tag-search.sql` | 25.944 ms | the `SELECT`, 25.943 |
| `place-order.sql` | 9.368 ms | the `COMMIT`, 6.939 |
| `seller-dashboard.sql` | 8.289 ms | the `SELECT`, 8.287 |
| `pending-count.sql` | 197.742 ms | the `SELECT`, 197.742 |

Two of these are worth a sentence each. **The purchase spends three quarters of its time in
`COMMIT`**: the two `INSERT`s and the `UPDATE` together take about 1.6 milliseconds, and the commit
6.9. A commit waits until the transaction's record is safely written to disk, so that is where a
write-heavy transaction's time goes on most machines, and no index would touch it. **The
`\set` lines cost a thousandth of a millisecond**: the client's own work, too small to matter in this
workload.

And the overall picture that the summary hid is now visible: three quarters of the transactions take about a
millisecond, a tenth take 26, and one in a hundred takes 198. The 6.5 milliseconds of the average is
nobody's experience. That is what the standard deviation was saying, and the percentiles of lesson 23
are the way to say it per user rather than per script.
