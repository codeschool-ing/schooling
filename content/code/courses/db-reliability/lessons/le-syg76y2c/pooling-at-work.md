---
title: 120 clients, 20 connections
version: 1
---

The same 120 `pgbench` clients that the server refused, now through PgBouncer on 6433, for ten
seconds. While they run, ask PgBouncer about its pools, through its admin console (the database
called `pgbouncer`), and measure how long one more query waits:

```
ana@vm:~$ pgbench -c 120 -T 10 -n -h 127.0.0.1 -p 6433 -U shop_app bench > ~/bench.out 2>&1 &
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app pgbouncer -c "SHOW POOLS" | cut -c1-80 | head -n 4
 database  |   user    | cl_active | cl_waiting | cl_active_cancel_req | cl_wait
-----------+-----------+-----------+------------+----------------------+--------
 bench     | shop_app  |        20 |        100 |                    0 |        
 pgbouncer | pgbouncer |         1 |          0 |                    0 |        
ana@vm:~$ time psql -h 127.0.0.1 -p 6433 -U shop_app -XAt bench -c "SELECT 1"
1

real	0m0.143s
user	0m0.041s
sys	0m0.007s
shop=# SELECT count(*) FROM pg_stat_activity WHERE usename = 'shop_app';
 count 
-------
    21
(1 row)
ana@vm:~$ grep -E "number of failed|latency average|tps" ~/bench.out
number of failed transactions: 0 (0.000%)
latency average = 73.210 ms
tps = 1639.120555 (without initial connection time)
```

`cl_active` 20, `cl_waiting` 100: twenty clients hold a server connection at this instant and a
hundred are queued for one. On the server, `shop_app` has **21** processes, the pool of 20 for `bench`
and the one serving `shop`. An extra `SELECT 1` arriving in the middle of it waited behind the queue
and finished in **0.143 seconds**. And `pgbench` itself reports **no failed transaction**: every one
of the 120 clients was served, through 20 connections, because in **transaction mode** a client holds
a server connection only for the length of one transaction and gives it back.

The queue is not free. Average latency is about **73 ms** here, against 2 ms in lesson 12 with four
clients; most of that is time spent waiting in PgBouncer's queue, which is where it should be spent,
instead of in a server with 120 processes fighting over four cores.
