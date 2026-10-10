---
title: The walls, and how far each one is
version: 1
---

Headroom is a slope; a wall is a cliff. The database is perfectly well until the moment it is not,
and the moment comes without a slow query to warn you. Five walls between them account for most of
the outages that are not a broken disk, and every one of them can be read from inside the database
long before it arrives:

```
market=# SELECT count(*) AS connections, current_setting('max_connections') AS max FROM pg_stat_activity WHERE backend_type = 'client backend';
 connections | max 
-------------+-----
           1 | 100
(1 row)

Time: 4.286 ms

market=# SELECT datname, age(datfrozenxid) AS xid_age, current_setting('autovacuum_freeze_max_age') AS freeze_max FROM pg_database WHERE datname = 'market';
 datname | xid_age | freeze_max 
---------+---------+------------
 market  |  526533 | 200000000
(1 row)

Time: 1.294 ms

market=# SELECT sequencename, data_type, last_value, max_value, round(100.0 * last_value / max_value, 4) AS pct_used FROM pg_sequences ORDER BY pct_used DESC;
   sequencename   | data_type | last_value |      max_value      | pct_used 
------------------+-----------+------------+---------------------+----------
 customers_id_seq | integer   |     200000 |          2147483647 |   0.0093
 products_id_seq  | integer   |      50000 |          2147483647 |   0.0023
 sellers_id_seq   | integer   |       1000 |          2147483647 |   0.0000
 orders_id_seq    | bigint    |    2016623 | 9223372036854775807 |   0.0000
 events_id_seq    | bigint    |    5000000 | 9223372036854775807 |   0.0000
(5 rows)

Time: 3.251 ms

market=# SELECT max(total_cents) AS largest_order, 2147483647 AS integer_limit FROM orders;
 largest_order | integer_limit 
---------------+---------------
         50499 |    2147483647
(1 row)

Time: 113.434 ms
```

## Connections

**1 of 100**: this `psql`, on a quiet machine. `max_connections` is fixed at start-up, and a client
that asks for the hundred-and-first connection is refused with an error rather than queued. Lesson
16 is about why raising the number is the wrong answer, and `db-administration` lesson 10 about the
setting itself. As a wall it is the nearest one on a busy application: an outage of the connection
pooler, a deploy that doubles the number of application processes, or a slow query that keeps every
connection busy, and the hundred are gone in seconds.

## The transaction counter

Every transaction that changes something takes a number from a 32-bit counter, and that counter
wraps around after about four billion. PostgreSQL's answer is to **freeze** old rows — mark them as
older than every transaction still running — which `VACUUM` does as it goes. `age(datfrozenxid)` is
how many transactions ago the oldest unfrozen row in the database was written: **526533** here. When
it reaches `autovacuum_freeze_max_age`, 200 million, autovacuum forces a freezing pass on the
tables that need it whether or not anything else is due. And if it ever came within a few million
of two billion, the server would refuse to start any new transaction until a manual vacuum had
caught up.

It is the wall that almost never arrives, because autovacuum is built to prevent it, and the one
with the worst consequence when it does, because the cure takes as long as reading the whole
database. What makes it arrive is something stopping `VACUUM` from freezing: a transaction left
open for days, which lesson 15 is about, or a replication slot nobody is reading.

## Sequences

The identity columns of `market` draw from sequences, and each one has a ceiling:

- `customers`, `products` and `sellers` use `integer`, whose ceiling is 2147483647;
- `orders` and `events` use `bigint`, whose ceiling is nine quintillion.

`pct_used` of `0.0093` for customers is far from anything, and `orders_id_seq` at 2016623 is above the
two million orders `market.sql` made — the purchases in this lesson's own workload runs, in the
section before, took numbers too, and a
sequence never gives a number back, not even when the row is deleted or the transaction rolls
back. A table that inserts and deletes a great deal uses its sequence much faster than its row
count suggests, and that is how an `integer` key reaches its ceiling on a table with a few thousand
rows in it.

The fix, changing a key from `integer` to `bigint`, rewrites the table and every index that
mentions it, and on a large table that is the outage you were trying to avoid. **It is a change to
make years early**, which is why the ceiling is worth reading now.

## A column's own limit

`total_cents` is an `integer`, so no single order may total more than 2147483647 cents — 21 million
reais. The largest is **50499**, so this one is a wall the shop will not meet. The same arithmetic
done on a column that sums rather than records, such as a running total per seller, comes out very
differently, and an `integer` column that overflows fails the `INSERT` that crossed it, with an
error, in production.

## The disk

The one wall the database cannot see from inside. `pg_database_size` says how much it uses, not how
much is left, and the space it shares with the log, the write-ahead log and the operating system is
only visible to `df`. When the disk fills, PostgreSQL stops accepting writes, and if the
write-ahead log cannot be written, it stops altogether. The last section's forecast is the
first defence; the alert in the next section is the second.
