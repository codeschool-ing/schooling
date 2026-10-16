---
title: Dropping one without regretting it
version: 1
---

Six of the leftovers have a case against them now: two duplicates, two overlapped by a longer
index, one overlapped and unread, and `orders_total_cents_idx`, which nothing reads and which
costs every update its HOT. Dropping an index takes milliseconds. **The risk is not in the drop,
it is in being wrong about it**, and in PostgreSQL there is no way to switch an index off and see
what happens: version 16 has no invisible or disabled index. So the safe drop is three habits:
keep the way back, drop without stopping the table, and measure afterwards.

## Keep the way back

`pg_get_indexdef` returns the exact statement that would build an index again, as the server
stored it. Write the six into a file before touching anything:

```sh
psql -XAt market > ~/dropped-indexes.sql <<'SQL'
SELECT pg_get_indexdef(indexrelid) || ';'
FROM pg_index
WHERE indexrelid IN ('orders_customer_idx'::regclass,
                     'order_lines_product_id_idx1'::regclass,
                     'orders_total_cents_idx'::regclass,
                     'orders_seller_id_idx'::regclass,
                     'orders_placed_at_status_idx'::regclass,
                     'order_lines_order_id_idx'::regclass);
SQL
```

`-A` and `-t` print the bare values with no table around them, and `-X` skips `~/.psqlrc`, so no
`Time:` line ends up in the file:

```
ana@vm:~$ cat ~/dropped-indexes.sql
CREATE INDEX orders_seller_id_idx ON public.orders USING btree (seller_id);
CREATE INDEX orders_customer_idx ON public.orders USING btree (customer_id);
CREATE INDEX orders_placed_at_status_idx ON public.orders USING btree (placed_at, status);
CREATE INDEX orders_total_cents_idx ON public.orders USING btree (total_cents);
CREATE INDEX order_lines_order_id_idx ON public.order_lines USING btree (order_id);
CREATE INDEX order_lines_product_id_idx1 ON public.order_lines USING btree (product_id);
```

That file is the undo. On a real system it goes into the migration that drops the indexes, as its
reverse step, so that putting one back is a reviewed change rather than somebody remembering a
column list at night.

## Drop without stopping the table

A plain `DROP INDEX` takes the strongest lock PostgreSQL has on the table, for the moment it
takes to remove the index. The moment is short, but the lock has to wait for every query already
running on the table, and while it waits every new query on the table waits behind it. Lesson 12
takes that queue apart; on a busy `orders` table it is how a two-millisecond drop becomes a
minute-long outage.

`DROP INDEX CONCURRENTLY` avoids that: it marks the index as no longer usable, waits for the
queries that might still be using it to finish, and only then removes it, without ever blocking
reads or writes on the table. It has two restrictions, and both show up as errors:

```
market=# BEGIN;
BEGIN
Time: 0.412 ms

market=*# DROP INDEX CONCURRENTLY orders_total_cents_idx;
ERROR:  DROP INDEX CONCURRENTLY cannot run inside a transaction block
Time: 0.475 ms

market=!# ROLLBACK;
ROLLBACK
Time: 0.352 ms

market=# DROP INDEX CONCURRENTLY orders_pkey;
ERROR:  cannot drop index orders_pkey because constraint orders_pkey on table orders requires it
HINT:  You can drop constraint orders_pkey on table orders instead.
Time: 1.467 ms
```

**It cannot run inside a transaction block**, because it commits more than once on its own while
it works; a migration tool that wraps every file in `BEGIN … COMMIT` has to be told to leave this
statement out of one. **And no form of `DROP INDEX` removes an index a constraint owns**: the
primary key's index goes only with the primary key, which is the server keeping the rule
section 03 of this lesson warned about.

The six, one at a time:

```
market=# DROP INDEX CONCURRENTLY orders_customer_idx;
DROP INDEX
Time: 16.957 ms

market=# DROP INDEX CONCURRENTLY order_lines_product_id_idx1;
DROP INDEX
Time: 24.680 ms

market=# DROP INDEX CONCURRENTLY orders_total_cents_idx;
DROP INDEX
Time: 14.936 ms

market=# DROP INDEX CONCURRENTLY orders_seller_id_idx;
DROP INDEX
Time: 18.813 ms

market=# DROP INDEX CONCURRENTLY orders_placed_at_status_idx;
DROP INDEX
Time: 53.193 ms

market=# DROP INDEX CONCURRENTLY order_lines_order_id_idx;
DROP INDEX
Time: 48.628 ms
```

Each under 60 ms on an idle machine. On a busy one, the time is mostly the wait for the queries
already running, and nobody else waits for it.

If a concurrent drop is interrupted, it can leave the index behind marked invalid: still
maintained on every write, never used for a read, which is the worst of both. `\d orders` shows it
with `INVALID` after its name; run the drop again. `db-administration` lesson 17 covers the same
failure for concurrent builds.

## Putting one back

Suppose the largest-orders report turns out to exist after all. The definition is in
`~/dropped-indexes.sql`; build it with `CONCURRENTLY` added, so the table keeps taking writes while
it builds:

```
market=# CREATE INDEX CONCURRENTLY orders_total_cents_idx ON orders (total_cents);
CREATE INDEX
Time: 1337.880 ms (00:01.338)

market=# DROP INDEX CONCURRENTLY orders_total_cents_idx;
DROP INDEX
Time: 12.287 ms
```

**1.3 seconds** for 2 million orders, and it was dropped again straight after. That number is the
real price of being wrong, and it grows with the table; for all of it, the report runs without its
index. That is why the undo file and the long counting
window of section 03 come before the drop, not after.

## And measure

The same six lines as in section 02 of this lesson, on the table as it is now:

```
market=# CHECKPOINT;
CHECKPOINT
Time: 95.387 ms

market=# SELECT pg_stat_reset();
 pg_stat_reset 
---------------
 
(1 row)

Time: 0.926 ms

market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.468 ms

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
latency average = 1.471 ms
initial connection time = 4.938 ms
tps = 2719.811049 (without initial connection time)

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal, round(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') / 20000) AS bytes_per_order;
  wal  | bytes_per_order 
-------+-----------------
 95 MB |            4993
(1 row)

Time: 0.927 ms

market=# SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
 n_tup_upd | n_tup_hot_upd 
-----------+---------------
     20000 |         19996
(1 row)

Time: 3.318 ms
```

| | before the leftovers | with them | after the drops |
|---|---|---|---|
| orders a second | 2809 | 2447 | 2720 |
| log per order | 4895 bytes | 9396 bytes | 4993 bytes |
| HOT updates | 19,996 | 0 | 19,996 |

The log is back within 2% of where it started, and HOT is back entirely, because `total_cents` is
no longer in any index. The two indexes that stayed from the leftovers, the seller dashboard's
and the operations screen's, are both read by the workload, and together they cost about 100 bytes
of log per order. **That is what an index that earns its place costs, and what the other six were
costing on top of it.**

## Back to the start

This lesson added and dropped indexes and wrote 74,503 orders. Put `market` back as lesson 12
expects it, with every `psql` on `market` closed first:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 12.252 ms
CREATE INDEX
Time: 919.533 ms
```

`~/leftovers.sql` and the three query files stay in your home directory. Keep the three queries:
`unused-indexes.sql`, `duplicate-indexes.sql` and `overlapping-indexes.sql` run unchanged on any
PostgreSQL database you are given.
