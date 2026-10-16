---
title: The write tax, measured
version: 1
---

The common picture of an index nobody uses is a file on the disk that costs some space and
otherwise sits there. **That picture is wrong in the direction that matters.** An index is a
second copy of some columns, kept in order, and PostgreSQL keeps every copy current on every
write: an `INSERT` into a table with nine indexes is ten inserts, whether or not any query ever
reads the other nine. The reading side is free to ignore an index. The writing side never is.

This section measures that cost on `market`, with lesson 2's `place-order.sql` as the write: one
order, one line, the total filled in, in one transaction. It starts from the database as
`~/reset-market.sh` leaves it and with the workload files from lesson 2 in `~/workload`.

## The baseline

Open `psql market` and type the six lines below. The first takes a **checkpoint**, so that both
runs start from the same state of the write-ahead log; why that matters comes further down. The
next two clear the activity counters and remember the log's current position in a psql variable.
Then pgbench runs 20,000 orders from inside psql, with `\!`, and the last two read how far the
log moved and how the 20,000 updates were done:

```
market=# CHECKPOINT;
CHECKPOINT
Time: 477.396 ms

market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.802 ms

market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.536 ms

market=# \! pgbench -n -c 4 -j 4 -t 5000 -f ~/workload/place-order.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/place-order.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
number of transactions per client: 5000
number of transactions actually processed: 20000/20000
number of failed transactions: 0 (0.000%)
latency average = 1.424 ms
initial connection time = 5.922 ms
tps = 2808.862523 (without initial connection time)

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal, round(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') / 20000) AS bytes_per_order;
  wal  | bytes_per_order 
-------+-----------------
 93 MB |            4895
(1 row)

Time: 1.094 ms

market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     20000 |         19996
(1 row)

Time: 3.863 ms
```

Three numbers to keep. **2809 orders a second at 1.424 ms each.** **93 MB of write-ahead log,
4895 bytes for every order.** And `n_tup_hot_upd`: 19,996 of the 20,000 updates were **HOT**,
heap-only tuple updates, which the next section of this page explains.

`pg_current_wal_lsn()` is the position the server has written the log up to, a byte address that
only grows; `pg_wal_lsn_diff` subtracts two of them. Everything the server changes goes into that
log before it goes anywhere else (`db-administration` lesson 7), so the difference is the total
amount of writing the run caused, in one number, whatever table or index it landed in.

## Three years of migrations

No team builds nine indexes on a table in one go. They arrive one migration at a time, each for a
screen or a report that somebody was looking at that week. This file is that history for `orders`
and `order_lines`, with the date and the reason on each line. Write it to your home directory and
run it:

```sh
cat > ~/leftovers.sql <<'SQL'
-- leftovers.sql: the indexes three years of migrations left on orders
-- and order_lines. Each one made sense to somebody on the day.
CREATE INDEX orders_customer_idx ON orders (customer_id);          -- 2023-03 support search
CREATE INDEX orders_seller_placed_idx ON orders (seller_id, placed_at); -- 2023-08 seller dashboard
CREATE INDEX orders_placed_at_status_idx ON orders (placed_at, status); -- 2024-01 monthly report
CREATE INDEX orders_status_idx ON orders (status);                 -- 2024-06 operations screen
CREATE INDEX orders_total_cents_idx ON orders (total_cents);       -- 2024-09 largest orders
CREATE INDEX order_lines_order_id_idx ON order_lines (order_id);   -- 2025-02 order page
CREATE INDEX ON order_lines (product_id);                          -- 2025-07 product sales
SQL
```

```
ana@vm:~$ psql market -f ~/leftovers.sql
CREATE INDEX
Time: 857.829 ms
CREATE INDEX
Time: 1253.471 ms (00:01.253)
CREATE INDEX
Time: 896.094 ms
CREATE INDEX
Time: 892.228 ms
CREATE INDEX
Time: 835.149 ms
CREATE INDEX
Time: 1481.093 ms (00:01.481)
CREATE INDEX
Time: 2061.541 ms (00:02.062)
```

Seven indexes in about eight seconds. The last line gives no name, so PostgreSQL makes one up,
and you will see in a moment what it chose. Every one of them is the size of a real index:

```
market=# SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_index WHERE indrelid IN ('orders'::regclass, 'order_lines'::regclass) ORDER BY indrelid, indexrelid;
            index            |  size  
-----------------------------+--------
 orders_pkey                 | 43 MB
 orders_customer_id_idx      | 18 MB
 orders_placed_at_idx        | 43 MB
 orders_seller_id_idx        | 14 MB
 orders_customer_idx         | 18 MB
 orders_seller_placed_idx    | 61 MB
 orders_placed_at_status_idx | 77 MB
 orders_status_idx           | 14 MB
 orders_total_cents_idx      | 14 MB
 order_lines_pkey            | 151 MB
 order_lines_product_id_idx  | 33 MB
 order_lines_order_id_idx    | 77 MB
 order_lines_product_id_idx1 | 33 MB
(13 rows)

Time: 2.487 ms
```

`orders` has gone from four indexes to nine, and `order_lines` from two to four. The seven new ones
add up to **294 MB**, a fifth of the whole database, and nothing about the tables themselves
changed.

## The same run, with the leftovers

Type the same six lines again:

```
market=# CHECKPOINT;
CHECKPOINT
Time: 149.390 ms

market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.726 ms

market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.542 ms

market=# \! pgbench -n -c 4 -j 4 -t 5000 -f ~/workload/place-order.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/place-order.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
number of transactions per client: 5000
number of transactions actually processed: 20000/20000
number of failed transactions: 0 (0.000%)
latency average = 1.635 ms
initial connection time = 4.397 ms
tps = 2447.139942 (without initial connection time)

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal, round(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') / 20000) AS bytes_per_order;
  wal   | bytes_per_order 
--------+-----------------
 179 MB |            9396
(1 row)

Time: 0.996 ms

market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     20000 |             0
(1 row)

Time: 4.016 ms
```

| | before | after |
|---|---|---|
| orders a second | 2809 | 2447 |
| latency | 1.424 ms | 1.635 ms |
| write-ahead log | 93 MB | 179 MB |
| log per order | 4895 bytes | 9396 bytes |
| HOT updates | 19,996 | 0 |

**The rate fell by 13% and the log nearly doubled.** The two numbers are not equally
trustworthy. The rate moves by several per cent between two runs of the same thing on this
machine, because what dominates one short transaction here is waiting for the disk to confirm a
commit, not maintaining indexes. The log volume does not move like that: it is bytes the server
wrote, and those bytes have to be stored, archived, sent to every replica and replayed after a
crash. **On a write-heavy system the log is where an index's cost lands first**, and it lands
there whether anybody is watching the transaction rate or not.

## Why the log doubled

Two things, and both are worth recognising when you see them again.

**A page image after every checkpoint.** The first time a page is changed after a checkpoint, the
server writes the whole 8 kB page into the log rather than just the change, so that a crash in the
middle of writing that page can be repaired (`db-administration` lesson 8). An index whose new
keys land all over it touches a different leaf page for almost every order: a random customer, a
random product, a random total. Each of those pages costs a full image once per checkpoint. An
index on something that only grows, like `placed_at` or `order_id`, adds every new key at the
right-hand end and touches the same few pages over and over. Four of the leftovers are of the
first kind: customer, seller, total and product all arrive in no particular order.

**The update stopped being cheap.** `place-order.sql` inserts the order with a total of zero and
then updates it. Before the leftovers, 19,996 of those updates were HOT: the new version of the
row went into the same page as the old one, and **no index had to be touched at all**, because
none of the indexed columns had changed. HOT is only possible when no index contains a column the
update changes. `orders_total_cents_idx` contains `total_cents`, so with it in place every update
had to insert a new entry into all nine indexes of `orders`, and the count fell to **0**. One
index on one column nobody searches by turned 20,000 cheap updates into 20,000 expensive ones.

Counted in index entries, one order went from six to twenty-two:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Index entries written for one order by place-order.sql. Before the leftovers: the order insert writes 4 index entries, the line insert 2, and the update none, because it is a HOT update; 6 in all. With the leftovers: the order insert writes 9, the line insert 4, and the update 9, because total_cents is now indexed; 22 in all.\"><text x=\"222\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">before the leftovers</text><text x=\"472\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">with the leftovers</text><text x=\"14\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO orders</text><rect x=\"222\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"294\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"520\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"592\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"616\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"664\" y=\"46\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"14\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO order_lines</text><rect x=\"222\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"472\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"520\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"96\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"14\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE orders SET total_cents</text><text x=\"222\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">HOT: no index touched</text><rect x=\"472\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"520\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"544\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"592\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"616\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"664\" y=\"146\" width=\"18\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><path d=\"M14 188 L706 188\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"14\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">index entries per order</text><text x=\"222\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">6</text><text x=\"472\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">22</text></svg>", "caption": "What one run of place-order.sql writes into indexes. The update is the step that changed most: HOT before, nine entries after."}
```

So the tax is not the same for every index. An index on a column that only grows is cheap to
keep. An index whose keys arrive in random order costs page images. **An index on a column that
gets updated costs the most, because it takes HOT away from every update of that column.** The
rest of this lesson finds which of the seven are paying for themselves, and the next section
starts with the obvious question: does anybody read them?
