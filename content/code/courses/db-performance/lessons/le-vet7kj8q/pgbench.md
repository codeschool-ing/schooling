---
title: pgbench, and the bank it ships with
version: 1
---

Every lesson since the second has used `pgbench` to make traffic. This lesson uses it to **measure**,
which is a different job: a number that will decide whether a change goes to production has to come
from a run that resembles production, and the first thing to know about `pgbench` is that, left to
itself, it resembles a bank.

## The built-in test

`pgbench` comes with a workload of its own, loosely modelled on an old industry benchmark called
TPC-B. It needs its own tables, so give it its own database, and let `-i` build them. `-s 10` is the
scale: ten branches, a hundred tellers and a million accounts:

```
ana@vm:~$ createdb bench
ana@vm:~$ pgbench -i -s 10 bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 1000000 tuples (10%) done (elapsed 0.05 s, remaining 0.45 s)
200000 of 1000000 tuples (20%) done (elapsed 0.11 s, remaining 0.44 s)
300000 of 1000000 tuples (30%) done (elapsed 0.17 s, remaining 0.39 s)
400000 of 1000000 tuples (40%) done (elapsed 0.24 s, remaining 0.35 s)
500000 of 1000000 tuples (50%) done (elapsed 0.29 s, remaining 0.29 s)
600000 of 1000000 tuples (60%) done (elapsed 0.36 s, remaining 0.24 s)
700000 of 1000000 tuples (70%) done (elapsed 0.41 s, remaining 0.18 s)
800000 of 1000000 tuples (80%) done (elapsed 0.48 s, remaining 0.12 s)
900000 of 1000000 tuples (90%) done (elapsed 0.54 s, remaining 0.06 s)
1000000 of 1000000 tuples (100%) done (elapsed 0.59 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.95 s (drop tables 0.00 s, create tables 0.00 s, client-side generate 0.61 s, vacuum 0.11 s, primary keys 0.22 s).
```

A million rows in under a second. And here is what each of its transactions does, printed by
`pgbench` itself:

```
ana@vm:~$ pgbench --show-script=tpcb-like
-- tpcb-like: <builtin: TPC-B (sort of)>
\set aid random(1, 100000 * :scale)
\set bid random(1, 1 * :scale)
\set tid random(1, 10 * :scale)
\set delta random(-5000, 5000)
BEGIN;
UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
END;
```

One account changes its balance, and the teller and branch it belongs to change theirs, and a line
goes into a history table. Run it the way lesson 2 ran the workload, eight clients on four threads
for thirty seconds:

```
ana@vm:~$ pgbench -c 8 -j 4 -T 30 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 119440
number of failed transactions: 0 (0.000%)
latency average = 2.010 ms
initial connection time = 8.750 ms
tps = 3979.789440 (without initial connection time)
```

**3980 transactions a second, 2 milliseconds each.** On the same machine, lesson 2's marketplace
workload runs at about a third of that, and the next section's report is around 1234. Neither number
is wrong. They are answers to two different questions, and only one of the questions is yours.

## Why it is not your workload

Read the script again with `market` in mind:

- **every transaction writes.** Three `UPDATE`s and an `INSERT` against one `SELECT`. The
  marketplace's traffic is mostly reads, with a tenth of it buying something.
- **ten branches.** With `-s 10` there are ten rows in `pgbench_branches`, and every transaction
  updates one of them. Eight clients are fighting over ten rows, so part of what this run measures
  is how fast row locks change hands — lesson 12's subject — and that depends on the scale more
  than on the server.
- **every key is equally likely.** `random(1, 100000 * :scale)` picks any account with the same
  probability. Real traffic has favourites: the busiest seller, this week's orders, the customers
  who come back.
- **it fits in memory many times over.** A million short rows, on a machine where lesson 1 found
  14 GB free.

**A benchmark measures a server running a workload, never a server alone.** Change the workload and
the number changes, and a change to the server — an index, a setting, a bigger machine — can help
one workload and do nothing for another. An index on `orders` would not move the bank's number at
all.

## What it is good for

The built-in test is a quick, repeatable load that anybody can reproduce from one command. That makes
it useful for one kind of question: **is this machine broken?** Two servers that should be the same
and give very different numbers on `pgbench -i -s 10`, or a new disk that halves the bank's
throughput, are worth knowing about before your own workload ever runs. For anything about your
application — will this index help, will this machine cope with December — the workload has to be
yours, and the next section builds it.

The bank's database is not needed again:

```
ana@vm:~$ dropdb bench
```
