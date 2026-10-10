---
title: What raising it costs
version: 1
---

When an application starts failing with `too many clients`, the obvious move is to raise
`max_connections`, and it works in the sense that the error stops. The trouble is what it costs,
and that it rarely fixes what was wrong. Raise it to a thousand and look:

```
ana@db:~$ psql shop -c "ALTER SYSTEM SET max_connections = 1000"
ALTER SYSTEM
ana@db:~$ sudo systemctl restart postgresql@16-main
ana@db:~$ psql shop -c "SHOW max_connections" -c "SHOW shared_memory_size"
 max_connections 
-----------------
 1000
(1 row)

 shared_memory_size 
--------------------
 184MB
(1 row)
```

## Memory before anybody connects

**Every slot is paid for at start, whether or not anybody uses it.** The server reserves shared
memory per slot for the bookkeeping of a backend that may never exist: its entry in the lock
tables, its place in the list of running transactions. The previous section saw 139 MB at five
slots and 143 MB at a hundred; a thousand slots ask for 184 MB, about 46 kB for each of the 900
added. On this machine that is small, and that is the cheapest part.

## Memory per connection

A connection that exists uses memory of its own, and it grows as the backend works. A backend can
report its own:

```
ana@db:~$ psql shop
shop=# SELECT pg_size_pretty(sum(total_bytes)) FROM pg_backend_memory_contexts;
 pg_size_pretty 
----------------
 1504 kB
(1 row)

shop=# \d+ orders
                                                               Table "public.orders"
   Column    |           Type           | Collation | Nullable |           Default            | Storage  | Compression | Stats target | Description 
-------------+--------------------------+-----------+----------+------------------------------+----------+-------------+--------------+-------------
 id          | bigint                   |           | not null | generated always as identity | plain    |             |              | 
 customer_id | bigint                   |           | not null |                              | plain    |             |              | 
 status      | text                     |           | not null |                              | extended |             |              | 
 total_cents | integer                  |           | not null |                              | plain    |             |              | 
 created_at  | timestamp with time zone |           | not null |                              | plain    |             |              | 
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
    "orders_created_at" btree (created_at)
    "orders_customer_id" btree (customer_id)
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id)
Access method: heap

shop=# SELECT pg_size_pretty(sum(total_bytes)) FROM pg_backend_memory_contexts;
 pg_size_pretty 
----------------
 2154 kB
(1 row)
```

A new backend held 1504 kB, and describing one table took it to 2154 kB, because the queries
behind `\d+` filled the backend's private caches of the catalogue. An application's connection
that has touched every table for hours holds much more, and none of it is shared. Then each
sort or hash a query runs may take up to `work_mem` on top, which lesson 6 worked out for a full
server. **A thousand connections is a thousand of all of that**, and the worst case is what decides
whether the machine runs out of memory.

## Throughput does not follow

The bigger surprise is the processors. `pgbench`, which comes with PostgreSQL, runs a small
standard workload against a database of its own; `--select-only` makes every transaction one
lookup by primary key, so the disk is out of the picture and only the processors count. Give it a
database and run it with four clients and then eighty:

```
ana@db:~$ createdb bench
ana@db:~$ pgbench --initialize --quiet --scale=10 bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
1000000 of 1000000 tuples (100%) done (elapsed 2.51 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 3.81 s (drop tables 0.00 s, create tables 0.00 s, client-side generate 2.55 s, vacuum 0.24 s, primary keys 1.01 s).
ana@db:~$ pgbench --select-only --client=4 --jobs=4 --time=15 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 10
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 15 s
number of transactions actually processed: 534211
number of failed transactions: 0 (0.000%)
latency average = 0.112 ms
initial connection time = 80.100 ms
tps = 35787.641500 (without initial connection time)
ana@db:~$ pgbench --select-only --client=80 --jobs=4 --time=15 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 10
query mode: simple
number of clients: 80
number of threads: 4
maximum number of tries: 1
duration: 15 s
number of transactions actually processed: 463481
number of failed transactions: 0 (0.000%)
latency average = 2.209 ms
initial connection time = 2265.701 ms
tps = 36209.255106 (without initial connection time)
```

`--scale=10` made a million rows in `pgbench_accounts`. **Twenty times the clients did the same
work**: 35,788 transactions a second with four, 36,209 with eighty. What changed is how long each
one waited, 0.112 ms on average with four clients and 2.209 ms with eighty, because the recording
machine has four processors and eighty backends took turns on them. Lesson 22 of
`db-performance` is about running benchmarks properly; these numbers are the recording machine's,
with `pgbench` itself competing for the same four processors, and yours will differ.

**More connections than processors do not add throughput; they add waiting.** The real fix for an
application that runs out of connections is usually that it holds them too long or opens too
many, and the next two sections are those two cases. Put the setting back before going on:

```
ana@db:~$ psql shop -c "ALTER SYSTEM RESET max_connections"
ALTER SYSTEM
ana@db:~$ sudo systemctl restart postgresql@16-main
```

`ALTER SYSTEM RESET` removed the line from `postgresql.auto.conf`, which lesson 5 showed, so the
default of 100 applies again.
