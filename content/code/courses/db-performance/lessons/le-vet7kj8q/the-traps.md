---
title: Five ways a benchmark lies
version: 1
---

A benchmark that resembles your workload can still report a number your production will never
see. The ways it goes wrong are few and they repeat, and each one has a symptom you can look for in
the run itself. None of them makes `pgbench` print an error.

## Too short

The progress lines of the previous section moved by 10% from one ten-second interval to the next.
A ten-second benchmark is one of those intervals, so it can report any of them, and a change
"measured" with one ten-second run before and one after is measuring which interval it landed on.

Short runs also miss what happens only now and then. PostgreSQL writes its changed pages to disk in
a **checkpoint**, every five minutes by default, and a checkpoint takes disk time away from the
queries running beside it. A thirty-second run either contains one or does not, and two runs that
differ only in that will differ in their numbers. The runs in this course are thirty or sixty seconds
because they demonstrate; a run whose number will decide something should be long enough to contain
the server's ordinary interruptions — several minutes, and longer than `checkpoint_timeout`.

## Cold, or warm

Lesson 1 measured one query cold and warm and found two and a half times between them. A whole
workload behaves the same way. Restart the server, drop the operating system's cache, and run with
progress every five seconds:

```
ana@vm:~$ sudo systemctl restart postgresql
ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -P 5 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(progress|tps)'
progress: 5.0 s, 1133.6 tps, lat 6.989 ms stddev 21.523, 0 failed
progress: 10.0 s, 1292.2 tps, lat 6.193 ms stddev 19.075, 0 failed
progress: 15.0 s, 975.4 tps, lat 8.136 ms stddev 26.475, 0 failed
progress: 20.0 s, 1085.8 tps, lat 7.432 ms stddev 23.731, 0 failed
progress: 25.0 s, 1103.4 tps, lat 7.218 ms stddev 22.940, 0 failed
progress: 30.0 s, 864.4 tps, lat 9.280 ms stddev 29.638, 0 failed
tps = 1073.036412 (without initial connection time)
```

On this machine the cold start barely shows: 1134 transactions a second in the first five seconds
against 1292 in the next, and then the run wandered between 864 and 1103 for reasons that had nothing
to do with the cache. The whole of `market` is 1.3 GB, and a fast disk hands that over in a few
seconds. **On a production database larger than its memory, the same restart is felt for hours**,
because the pages warm up only as queries ask for them. Decide which one you are measuring — the
server right after a deploy, or the server on an ordinary afternoon — and either way, run once and
discard it before the runs you keep. The repeat section's first run after a fresh copy of `market`
shows what that discarded run looks like.

## The client on the same machine

`pgbench` is a program, and on your machine it runs beside the server it measures, taking processor
time the server would otherwise have had. How much is easy to find out:

```
ana@vm:~/workload$ time pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^tps'
tps = 1368.504074 (without initial connection time)

real	0m30.116s
user	0m0.711s
sys	0m0.384s
ana@vm:~$ nproc
4
```

Thirty seconds on four processors is 120 seconds of processor time, and `pgbench` used **1.1 of them**
(`user` plus `sys`): under one percent. For this workload, whose statements take milliseconds each,
the client is cheap. The cheaper each statement, the larger the client's share. For a workload of tiny
statements at tens of thousands a second, check this line before trusting the number, and for
anything that matters, run the client on another machine, as production's application servers are.

The same machine also hides the network. Here the clients reach the server through a local socket;
in production every statement crosses a network, and a workload of many short statements pays that
trip on each one. A benchmark run next to the database reports latencies the application will not
see.

## Less data than production

```
market=# SELECT pg_size_pretty(pg_database_size('market'));
 pg_size_pretty 
----------------
 1352 MB
(1 row)

Time: 3.437 ms
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       918Mi        13Gi       156Mi       1.5Gi        14Gi
Swap:             0B          0B          0B
```

**1352 MB of database against 14 GB of available memory**: every page of `market` fits in the
operating system's cache with room to spare, so after the first minute this course's benchmarks
measure a database that never touches the disk. A production database ten times larger than its
server's memory behaves differently in every way that matters. Reads go to the disk, and an index
that fitted in memory no longer does. The plan itself may change with the size of the tables: lesson 4
showed the crossing points move with the row counts.

A benchmark against a small copy of production says how the small copy performs. To say anything
about production, run against a copy of production's size, or at least of the same size relative to
memory.

## The loop that hides the queue

Every run so far has been a **closed loop**: each of the eight clients sends its next transaction
only when the last one has returned. When the server slows down, the clients slow down with it, and
the transactions that would have arrived during the slow moment simply are not sent. Real users do
not wait for each other like that; they arrive when they arrive.

`-R` makes `pgbench` behave like users: it schedules transactions at a fixed rate, whether or not
the server has caught up, and counts the wait for a transaction's turn as part of its latency:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 900 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency|rate)'
latency average = 17.136 ms
latency stddev = 36.235 ms
rate limit schedule lag: avg 12.970 (max 307.706) ms
tps = 900.173812 (without initial connection time)
```

At **900 a second**, fewer than the closed loop's 1234, the average latency is **17.1 milliseconds**,
not 6.5 — and 13.0 of them are `schedule lag`, the time a transaction waited behind the ones before
it, up to 308 milliseconds for the unluckiest. The closed loop's 6.5 was not wrong about the
transactions it sent. It was silent about the ones it never sent while the server was busy. **A
latency measured in a closed loop is the latency of a server that is never asked for more than it
can give**, which production is not.

Lesson 23 uses `-R` to find how latency grows as the rate approaches the maximum, and that curve is
where capacity planning starts. For a benchmark, the rule is shorter: report throughput from a
closed loop if you like, but report latency at a fixed rate close to the real one.
