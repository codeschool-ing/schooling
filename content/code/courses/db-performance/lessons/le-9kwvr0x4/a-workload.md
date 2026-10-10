---
title: A morning's traffic, in a minute
version: 1
---

A database on its own runs nothing. Its statements come from an application: screens people open,
buttons people press, jobs that run at night. To find out what costs the server the most, you need
that traffic, and on a machine of your own there is none — so you make some, with `pgbench`.

`pgbench` comes with PostgreSQL and is usually met as a benchmark with its own tables. It also runs
**scripts you write**: a file of SQL, with variables drawn at random for each run, executed over and
over by as many simulated clients as you ask for. Six files make a small marketplace's morning.
Each one is a thing a person or a screen does, with a comment saying which:


```sh
mkdir -p ~/workload && cd ~/workload

cat > customer-orders.sql <<'SQL'
-- A customer opens "my orders": the last ten, newest first.
\set c random(1, 200000)
SELECT id, placed_at, status, total_cents
FROM orders WHERE customer_id = :c
ORDER BY placed_at DESC LIMIT 10;
SQL

cat > order-page.sql <<'SQL'
-- One order's page: its lines, with each product's title.
\set o random(1, 2000000)
SELECT p.title, l.quantity, l.price_cents
FROM order_lines AS l JOIN products AS p ON p.id = l.product_id
WHERE l.order_id = :o;
SQL

cat > tag-search.sql <<'SQL'
-- Browsing a tag: twenty products, cheapest first.
\set t random(1, 5)
SELECT id, title, price_cents FROM products
WHERE tags @> ARRAY[(ARRAY['home', 'kitchen', 'office', 'outdoor', 'kids'])[:t]]
ORDER BY price_cents LIMIT 20;
SQL

cat > place-order.sql <<'SQL'
-- Somebody buys something: one order, one line, the total filled in.
\set c random(1, 200000)
\set s random(1, 1000)
\set p random(1, 50000)
BEGIN;
INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)
VALUES (:c, :s, now(), 'pending', 0) RETURNING id AS order_id \gset
INSERT INTO order_lines (order_id, line, product_id, quantity, price_cents)
SELECT :order_id, 1, id, 1, price_cents FROM products WHERE id = :p;
UPDATE orders SET total_cents = (SELECT sum(quantity * price_cents)
                                 FROM order_lines WHERE order_id = :order_id)
WHERE id = :order_id;
COMMIT;
SQL

cat > seller-dashboard.sql <<'SQL'
-- A seller's dashboard: December, day by day.
\set s random(2, 1000)
SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents)
FROM orders
WHERE seller_id = :s AND placed_at >= '2025-12-01'
GROUP BY 1 ORDER BY 1;
SQL

cat > pending-count.sql <<'SQL'
-- The operations screen, refreshed by everybody who has it open.
SELECT count(*) FROM orders WHERE status = 'pending';
SQL
```

Copy the whole block and paste it at your prompt: it makes the directory and writes the six files
into it.

```
ana@vm:~$ ls ~/workload
customer-orders.sql
order-page.sql
pending-count.sql
place-order.sql
seller-dashboard.sql
tag-search.sql
```

## A minute of traffic

`pgbench` takes the files with `-f`, each with a **weight** after `@`: out of every hundred
transactions, fifty are a customer's order list, twenty-five an order page, ten tag searches, ten
purchases, four seller dashboards and one refresh of the operations screen. The other options say
how hard to push: `-c 8` is eight clients at once, `-j 4` runs them on four threads, `-T 60` for sixty
seconds, `-P 20` prints progress every twenty, and `-n` skips the clean-up `pgbench` would otherwise
try to do on its own benchmark tables, which `market` does not have:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 20.0 s, 796.5 tps, lat 9.986 ms stddev 31.316, 0 failed
progress: 40.0 s, 972.7 tps, lat 8.247 ms stddev 25.464, 0 failed
progress: 60.0 s, 972.0 tps, lat 8.238 ms stddev 24.896, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 54833
number of failed transactions: 0 (0.000%)
latency average = 8.756 ms
latency stddev = 27.129 ms
initial connection time = 9.223 ms
tps = 912.697830 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 27488 transactions (50.1% of total, tps = 457.539036)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.912 ms
 - latency stddev = 2.028 ms
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 13786 transactions (25.1% of total, tps = 229.468610)
 - number of failed transactions: 0 (0.000%)
 - latency average = 1.027 ms
 - latency stddev = 2.113 ms
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 5496 transactions (10.0% of total, tps = 91.481175)
 - number of failed transactions: 0 (0.000%)
 - latency average = 31.417 ms
 - latency stddev = 12.690 ms
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 5354 transactions (9.8% of total, tps = 89.117579)
 - number of failed transactions: 0 (0.000%)
 - latency average = 12.862 ms
 - latency stddev = 31.163 ms
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 2164 transactions (3.9% of total, tps = 36.019880)
 - number of failed transactions: 0 (0.000%)
 - latency average = 36.674 ms
 - latency stddev = 15.144 ms
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 540 transactions (1.0% of total, tps = 8.988325)
 - number of failed transactions: 0 (0.000%)
 - latency average = 222.128 ms
 - latency stddev = 59.235 ms
```

About nine hundred transactions a second for a minute, **54833** in all, none failed. The report ends
with a block per script, and two numbers in it are already worth reading. The average latency of a
customer's order list is **0.912 milliseconds**, and of the operations screen's count **222
milliseconds**, two hundred and forty times as long. And yet the script that people would complain
about is not necessarily the one that costs the server the most, which is what the next section
asks the tally.

**Your numbers will differ** from these in every digit, because they depend on your processors and
your disk. What should match is the shape: the order list and the order page under a couple of
milliseconds, the tag search and the dashboard in the tens, the pending count in the hundreds.

## Why it is shaped like this

The weights are not measured from a real shop. They are a guess at a plausible one: many cheap
reads, a few expensive ones, a trickle of writes. That is good enough to give the tally a realistic
picture to show you, and it is the reason lesson 22 spends a whole section on what makes a
workload **representative** — the day you need to measure a change that matters, a guessed workload
is the first thing to replace.

Two of the scripts change the database. `place-order.sql` inserts an order and a line and updates
the total in one transaction, which is what makes the writes in this workload real writes, with
locks and indexes to maintain. Every run of it adds a row to `orders`. Section 05 of this lesson
shows how to put `market` back to the rows `market.sql` made.
