---
title: Sizing the pool from a measurement
version: 1
---

`default_pool_size = 8` was a guess. The pool size is the number of transactions the server works
on at once, so it is the knob section 03's curve was about, moved from the application to
PgBouncer. Too small and the server idles while clients wait in the pool; too large and the clients
wait inside the server instead, in its queues, at a higher price. The right size is the bend in the
curve, and the way to find it is to measure.

## Changing it without a restart

PgBouncer's console, the pseudo-database `pgbouncer` that `admin_users` let you into, takes `SET`
for most settings and applies it at once. Two hundred clients, lesson 2's mix, twenty seconds, at
five pool sizes:

```
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 2"
SET default_pool_size=2
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 241.050 ms
tps = 829.703130 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 4"
SET default_pool_size=4
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 179.263 ms
tps = 1115.679412 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 8"
SET default_pool_size=8
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 161.900 ms
tps = 1235.333375 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 16"
SET default_pool_size=16
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 154.251 ms
tps = 1296.591974 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 32"
SET default_pool_size=32
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 147.839 ms
tps = 1352.819242 (without initial connection time)
```

## Reading it

| pool size | tps | average latency |
|---|---|---|
| 2 | 830 | 241 ms |
| 4 | 1116 | 179 ms |
| 8 | 1235 | 162 ms |
| 16 | 1297 | 154 ms |
| 32 | 1353 | 148 ms |

Two server connections are clearly too few: **830 transactions a second**, with 198 clients
waiting for two connections. Four are a third better, 1116. After that the line flattens: 1235 at
eight, 1297 at sixteen, 1353 at thirty-two, each doubling buying less than the one before.

How much less matters, because lesson 1's rule applies here: **a difference smaller than the noise
is not a difference.** The same pool of eight, run twice in this lesson, gave 1235 here and 1342 in
section 04. That is 107 transactions apart for no change at all. Every step from eight upwards is smaller
than that. So the honest reading is that the bend is **between four and eight**, as section 03's
curve put it at about the processor count, and that above it this machine cannot tell the sizes
apart.

When the measurements cannot tell two sizes apart, **take the smaller one.** It does the same work
with fewer server processes, leaves more of `max_connections` for everything else, and when one
transaction turns slow it holds up a smaller share of the server. A pool of thirty-two on four
processors is ninety clients' worth of contention moved back inside the server.

## A rule of thumb, and why it is only a start

A common starting point is a pool of **about twice the processor count**, plus a little for
connections that wait on the disk. On four processors that is eight to ten, which is close to what
the measurement found. Treat it as the first number to measure, never the answer: a workload that
waits on the disk or on locks wants more, one that is pure computation wants fewer, and the only
way to know which yours is the run above.

Three more things decide the real number in production, and they are worth naming here even though
this machine has only one of each:

- **Every pool adds up.** `default_pool_size` is per database and role. Three application servers,
  each running its own PgBouncer with a pool of 20, are 60 connections at the database. The sum is
  what has to stay under the bend, and under `max_connections`.
- **Leave room for the people.** Migrations, a `psql` for an incident, monitoring, a backup: they
  connect directly, and the limit has to have space for them when the pools are full. The three
  superuser slots are for the last resort, not for this.
- **The pool caps the work, so watch the wait.** With the pool full, a slow query does not slow the
  server, it slows the queue: `cl_waiting` and `maxwait` in `SHOW POOLS` are the numbers to graph
  and alert on. `db-reliability` lesson 18 is about running PgBouncer that way: its own
  availability, its logs, and its place in a failover.

## Putting the machine back

Everything this lesson changed outside `market` is undone the way it was done: stop PgBouncer and
keep it from starting at boot, put its original configuration back, empty its user list, remove the
password file and the password:

```
ana@vm:~$ sudo systemctl disable --now pgbouncer
Synchronizing state of pgbouncer.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable pgbouncer
ana@vm:~$ sudo mv /etc/pgbouncer/pgbouncer.ini.orig /etc/pgbouncer/pgbouncer.ini
ana@vm:~$ sudo truncate -s 0 /etc/pgbouncer/userlist.txt
ana@vm:~$ rm ~/.pgpass
market=# ALTER ROLE ana PASSWORD NULL;
ALTER ROLE
Time: 1.440 ms
```

The workload wrote orders, so finish with `market` as lesson 17 starts:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 10.848 ms
CREATE INDEX
Time: 700.261 ms
```
