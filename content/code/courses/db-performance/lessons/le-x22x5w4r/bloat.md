---
title: Bloat, measured
version: 1
---

One dead version is a curiosity. A table that is updated a few thousand times a second makes a few
thousand of them every second, and while the horizon is held none of them can go. The table grows,
and **every query that reads the table pays for the growth**, including queries that have nothing to
do with the transaction holding the horizon. That is the cost this lesson's title promises, and it
is measurable in one minute.

## A table that is updated all day

Lesson 2's workload writes, but mostly new rows. What makes old versions quickly is the same rows
updated over and over: a stock counter, a session's last-seen time, a price. Add one more script to
`~/workload`, a robot that nudges one product's price at a time:

```sh
cat > ~/workload/reprice.sql <<'SQL'
-- A pricing robot: one product's price nudged up or down, all day long.
\set p random(1, 50000)
\set delta random(-10, 10)
UPDATE products SET price_cents = price_cents + :delta WHERE id = :p;
SQL
```

It changes prices in `market`, so the end of this lesson puts the database back with
`~/reset-market.sh`. Before it runs, measure two things: the size of `products`, and how long
lesson 2's tag search takes, because that search reads the whole of `products` on every run (lesson
8 gives it an index; until then it is a sequential scan, which makes it a fair witness here):

```
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
  size   | n_live_tup | n_dead_tup 
---------+------------+------------
 5232 kB |      50000 |          0
(1 row)

Time: 9.243 ms
```

```
ana@vm:~/workload$ pgbench -n -T 10 -f tag-search.sql market | tail -3
latency average = 14.475 ms
initial connection time = 3.117 ms
tps = 69.084194 (without initial connection time)
```

**5232 kB** and **14.5 milliseconds** a search. Now let the robot run for thirty seconds, with
nothing else open:

```
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 30 -f reprice.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: reprice.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 141981
number of failed transactions: 0 (0.000%)
latency average = 0.845 ms
initial connection time = 12.377 ms
tps = 4734.588470 (without initial connection time)
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
  size   | n_live_tup | n_dead_tup 
---------+------------+------------
 5544 kB |      50000 |       3341
(1 row)

Time: 5.729 ms
```

**141981 updates**, nearly five thousand a second, and the table grew from 5232 to 5544 kB. Most of
the old versions were cleaned as the robot went: when a page fills up, the next statement that
touches it removes the versions nobody can see, without waiting for `VACUUM`, and the new ones reuse
the space. The **3341** dead versions left are the ones made since the last tidy-up of their page.

## The same thirty seconds, with a transaction open

Open Session A again and leave it, exactly as in the previous section:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.371 ms

market=*# SELECT count(*) FROM products;
 count 
-------
 50000
(1 row)

Time: 7.940 ms
```

and run the robot once more, for the same thirty seconds:

```
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 30 -f reprice.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: reprice.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 139519
number of failed transactions: 0 (0.000%)
latency average = 0.860 ms
initial connection time = 7.677 ms
tps = 4651.674843 (without initial connection time)
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
 size  | n_live_tup | n_dead_tup 
-------+------------+------------
 19 MB |      49902 |     139122
(1 row)

Time: 4.456 ms
```

A similar number of updates, **139519**, and this time the table went from 5544 kB to **19 MB**,
more than three times its size, with **139122** dead versions in it. Nothing could be cleaned on the
way, so every update put its new version in fresh space at the end of the table. `VACUUM` confirms
it is not a matter of waiting:

```
market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 0
pages: 0 removed, 2484 remain, 2484 scanned (100.00% of total)
tuples: 0 removed, 189519 remain, 139519 are dead but not yet removable
removable cutoff: 1240919, which was 139520 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan not needed: 0 pages from table (0.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 5020 hits, 0 misses, 0 dirtied
WAL usage: 1 records, 0 full page images, 188 bytes
system usage: CPU: user: 0.02 s, system: 0.00 s, elapsed: 0.02 s
INFO:  vacuuming "market.pg_toast.pg_toast_16498"
INFO:  finished vacuuming "market.pg_toast.pg_toast_16498": index scans: 0
```

`139519 are dead but not yet removable`, and the cutoff is `139520 XIDs old`: the robot's
transactions, every one of them after Session A's snapshot. And the bystander, lesson 2's tag
search, which never touched Session A and never changed a price:

```
ana@vm:~/workload$ pgbench -n -T 10 -f tag-search.sql market | tail -3
latency average = 21.121 ms
initial connection time = 3.176 ms
tps = 47.345969 (without initial connection time)
```

**21.1 milliseconds** against 14.5 before, because a sequential scan reads every page of the table
and there are now more than three times as many. Every query that scans `products`, every report,
every backup, now reads 19 MB to find 5 MB of rows.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A chart of transaction numbers over time. The newest transaction number rises steeply from 1240919 to 1380439 while the pricing robot runs for thirty seconds. The horizon, VACUUM&#x27;s removable cutoff, stays flat at 1240919 for as long as Session A&#x27;s transaction is open, and jumps to 1380439 when Session A commits. The gap between the two lines is the 139519 dead versions VACUUM had to keep.\"><text x=\"14\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">transaction number</text><path d=\"M100 230 L690 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M100 40 L100 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"94\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">1380439</text><text x=\"94\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">1240919</text><path d=\"M190 220 L430 70 L520 70 L520 220 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></path><path d=\"M110 220 L190 220 L430 70 L690 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M110 220 L520 220 L520 70 L690 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 3\"></path><text x=\"310\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">newest transaction</text><text x=\"528\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">horizon (removable cutoff)</text><text x=\"510\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"end\" fill=\"var(--paper)\">139519 dead versions</text><text x=\"510\" y=\"166\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">VACUUM may not remove</text><path d=\"M110 230 L110 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M190 230 L190 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M430 230 L430 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M520 230 L520 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"110\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">Session A begins</text><text x=\"190\" y=\"268\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">robot starts</text><text x=\"430\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">robot stops, 30 s later</text><text x=\"520\" y=\"268\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">Session A commits</text></svg>", "caption": "The horizon over the thirty seconds of the robot. Everything between the two lines is a dead version VACUUM may not remove."}
```

## Closing the transaction does not shrink the table

Commit in Session A, and run `VACUUM` again:

```
market=*# COMMIT;
COMMIT
Time: 0.271 ms
```

```
market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 1
pages: 0 removed, 2484 remain, 2484 scanned (100.00% of total)
tuples: 139519 removed, 50000 remain, 0 are dead but not yet removable
removable cutoff: 1380439, which was 0 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan needed: 2473 pages from table (99.56% of total) had 137869 dead item identifiers removed
index "products_pkey": pages: 499 in total, 0 newly deleted, 0 currently deleted, 0 reusable
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 7998 hits, 0 misses, 0 dirtied
WAL usage: 7929 records, 0 full page images, 1468201 bytes
system usage: CPU: user: 0.10 s, system: 0.00 s, elapsed: 0.11 s
INFO:  vacuuming "market.pg_toast.pg_toast_16498"
INFO:  finished vacuuming "market.pg_toast.pg_toast_16498": index scans: 0
pages: 0 removed, 0 remain, 0 scanned (100.00% of total)
tuples: 0 removed, 0 remain, 0 are dead but not yet removable
removable cutoff: 1380439, which was 0 XIDs old when operation ended
new relfrozenxid: 1380439, which is 139520 XIDs ahead of previous value
frozen: 0 pages from table (100.00% of total) had 0 tuples frozen
index scan not needed: 0 pages from table (100.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 28 hits, 0 misses, 0 dirtied
WAL usage: 1 records, 0 full page images, 188 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
VACUUM
Time: 116.511 ms
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
 size  | n_live_tup | n_dead_tup 
-------+------------+------------
 19 MB |      50000 |          0
(1 row)

Time: 4.601 ms
```

`139519 removed`, nothing dead left. And **the table is still 19 MB.** `VACUUM` turns the space of
dead versions into free space inside the table's pages, ready for new versions, but it does not give
it back to the operating system except for empty pages at the very end of the file — and the
robot's live rows are spread all over it. The search is hardly better, because it still reads
every page, and most of them are now largely empty:

```
ana@vm:~/workload$ pgbench -n -T 10 -f tag-search.sql market | tail -3
latency average = 19.440 ms
initial connection time = 4.648 ms
tps = 51.439456 (without initial connection time)
```

**19.4 milliseconds**, against 14.5 before any of this. The free space will be reused by later
updates, so the table stops growing; it does not come back to 5 MB on its own. Getting the space
back means rewriting the table, with `VACUUM FULL` or a tool such as `pg_repack`, each with locks and
costs of its own. `db-administration` lessons 14 and 15 are about autovacuum and about measuring and removing
**bloat**, the name for this dead weight. The point here is the order of events: half a minute of a
forgotten transaction left a table more than three times its size, and the price is paid by every
query on it until somebody rewrites it.

## Why thirty seconds is the gentle case

The robot ran for thirty seconds, at about **4650 updates a second**. A transaction left open by a
person or a bug stays open for hours, and the arithmetic is unkind: at that rate an hour is more
than sixteen million dead versions on one table, every one of them kept, and every other table
updated in that hour grows the same way. The symptom people notice is not the transaction, which
nobody is looking at; it is a screen that reads `products` getting slower all afternoon for no reason
anybody can find in its own query.

**Two numbers** recognise it every time: the age of the cutoff that `VACUUM VERBOSE` prints, and a
count of dead rows in `pg_stat_user_tables` that does not go down after `VACUUM` has run. Section 05
of this lesson turns the first into a query you can run every minute.
