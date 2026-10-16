---
title: A workload shaped like yours
version: 1
---

Lesson 2 wrote six scripts and weighted them 50, 25, 10, 10, 4 and 1, and said plainly that the
weights were a guess. A guess is fine for making traffic to look at. It is not fine for a benchmark
whose number will decide something, because **the mix is the workload**: the same six scripts in
other proportions are a different load, with a different bottleneck.

A workload reproduces the real one along four lines, and each can be checked:

| what | where the real value comes from |
|---|---|
| **which statements**, in what proportion | `pg_stat_statements` on the production server |
| **which parameters** — which customers, which sellers, which dates | the application's own logs, or the data's shape |
| **how many at once** | the number of active connections at the busy hour |
| **against how much data** | the production database's size, or a copy of it |

The last two are traps of their own, and section 05 takes them up. This section does the first two.

## Weights from the tally

`pg_stat_statements` already counts how many times each statement ran. Reset it at the start of a
period that represents the load you care about — the busy hour of an ordinary weekday, not the
quiet night — and read it at the end. Each script needs one statement that identifies it, and its
share of the calls is the script's weight. This file does the reading:

```sh
cat > ~/workload/weights.sql <<'SQL'
-- weights.sql: each script's share of the calls pg_stat_statements counted,
-- read through the one statement that identifies the script.
SELECT CASE
         WHEN query LIKE 'SELECT id, placed_at%'          THEN 'customer-orders.sql'
         WHEN query LIKE 'SELECT p.title%'                THEN 'order-page.sql'
         WHEN query LIKE 'SELECT id, title%'              THEN 'tag-search.sql'
         WHEN query LIKE 'INSERT INTO orders%'            THEN 'place-order.sql'
         WHEN query LIKE 'SELECT date_trunc%'             THEN 'seller-dashboard.sql'
         WHEN query LIKE 'SELECT count(*) FROM orders WHERE status%' THEN 'pending-count.sql'
       END AS script,
       calls,
       round(100.0 * calls / sum(calls) OVER (), 1) AS weight
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market')
  AND (query LIKE 'SELECT id, placed_at%' OR query LIKE 'SELECT p.title%'
       OR query LIKE 'SELECT id, title%' OR query LIKE 'INSERT INTO orders%'
       OR query LIKE 'SELECT date_trunc%'
       OR query LIKE 'SELECT count(*) FROM orders WHERE status%')
ORDER BY calls DESC;
SQL
```

`place-order.sql` is counted through its first `INSERT`, because its `BEGIN`, its second `INSERT`,
its `UPDATE` and its `COMMIT` would count the same transaction four more times.

On your machine there is no production, so the traffic to read has to be made, and the honest
stand-in is lesson 2's own workload: if the query is right, it must give back the weights lesson 2
put in. Reset the tally, run the workload for a minute with its output thrown away, and read:

```
market=# SELECT pg_stat_statements_reset();
 pg_stat_statements_reset 
--------------------------
 
(1 row)

Time: 2.049 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market > /dev/null
ana@vm:~$ psql market -f ~/workload/weights.sql
        script        | calls | weight 
----------------------+-------+--------
 customer-orders.sql  | 33449 |   50.0
 order-page.sql       | 16668 |   24.9
 place-order.sql      |  6728 |   10.1
 tag-search.sql       |  6706 |   10.0
 seller-dashboard.sql |  2629 |    3.9
 pending-count.sql    |   695 |    1.0
(6 rows)

Time: 3.941 ms
```

**50.0, 24.9, 10.1, 10.0, 3.9 and 1.0** — the weights lesson 2 wrote, recovered from nothing but what
the server counted. That round trip is the check that the reading works. On a real server the same
file prints the real mix, and those numbers become the `@50`, `@25` and the rest of the `pgbench`
command line.

## Parameters matter as much as statements

A script's `\set` line decides **which rows** each run touches, and `random(a, b)` makes every value
equally likely. Real traffic is never like that. In `market`, seller 1 owns a quarter of all orders,
and lesson 2's dashboard script quietly avoids it with `random(2, 1000)`. A dashboard asked the way
real sellers would ask — the biggest one often, the long tail rarely — is this file, which differs
from lesson 2's in its `\set` line alone:

```sh
cat > ~/workload/seller-dashboard-skewed.sql <<'SQL'
-- The seller dashboard, asked about sellers the way real traffic does:
-- the biggest seller most often, the long tail rarely.
\set s random_zipfian(1, 1000, 1.07)
SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents)
FROM orders
WHERE seller_id = :s AND placed_at >= '2025-12-01'
GROUP BY 1 ORDER BY 1;
SQL
```

`random_zipfian(1, 1000, 1.07)` draws seller 1 most often, seller 2 about half as often, and so on
down the tail. Run each version alone for twenty seconds:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 20 -f seller-dashboard.sql market | grep -E "^(tps|latency)"
latency average = 9.016 ms
tps = 887.320360 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 20 -f seller-dashboard-skewed.sql market | grep -E "^(tps|latency)"
latency average = 15.233 ms
tps = 525.177215 (without initial connection time)
```

**887 dashboards a second with every seller equally likely, 525 with the skew** — 9 milliseconds
each against 15. Same statement, same indexes, same server; the only change is which sellers were
asked about, and the big seller's December has far more rows to count. A benchmark built on the
uniform version would have promised 70% more dashboard capacity than the shop has.

The same question applies to every `\set` in a workload. Customers who come back are more likely to
open their orders than customers who bought once; today's orders are read far more than 2023's.
When the parameters cannot be read from logs, the shape of the data is the next best source: the
counts per seller, per customer, per day, from a `GROUP BY` on the real tables.

## How many clients

`-c 8` in every run of this course is a choice for a four-processor machine, not a fact about the
shop. The production number is the count of connections that are **active** at the busy hour —
`pg_stat_activity` with `state = 'active'`, sampled every few seconds — not the size of the
connection pool, most of which sits idle. Lesson 16 is about what too many connections cost; here
the rule is only that the benchmark should offer the server the concurrency it really sees.
