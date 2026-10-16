---
title: The run, against what was expected
version: 1
---

Three nodes, all current. Run it:

```
ana@vm:~$ ./rehearsal.sh
03:14:05 healthy: 3 members, leader pg1, lag 0
03:14:10 killing pg1
orders ok: 16, failed: 24
first failure: 03:14:16
back at: 03:14:41 ok on 5443
new rows in the table: 16
+ Cluster: shop (7697144668418349739) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
```

Compared with the plan:

| | expected | measured |
|---|---|---|
| new leader | within about 30 seconds | `pg3`, on timeline 2 |
| orders during the failure | fail, then succeed | 24 failed, 16 succeeded |
| seconds without orders | about 30 | 31, from 03:14:10 to 03:14:41 |
| rows against orders reported `ok` | equal | 16 and 16 |
| the killed node | back as a replica | `pg1` streaming on timeline 2 |

Everything as expected, and one detail worth a line in the results: the first failure came at
03:14:16, **six seconds** after the kill, not one. By the timestamps, the attempt that began just after the
kill waited out its five-second timeout before failing, which is the timeout doing its job; without it, that order is the one that
would have hung.

## What the first run found

The first time this rehearsal ran, while this course was being written, it **never finished**. One of
`orders.sh`'s connections, opened through HAProxy in the instant the leader died, was left waiting for
an answer that would never come: HAProxy held the client's side open, with nothing behind it, and
`psql` had no limit of its own. Eight minutes later it was still waiting, and the rehearsal with it;
HAProxy's `timeout client` in lesson 19's file is thirty minutes.

For the rehearsal that was an inconvenience. For an application it is the incident lesson 22 did not
show: a request thread stuck for half an hour on one connection, then another, until none is left and
the shop is down **after** the failover has finished. The finding became a line at the top of the
script, `export PGCONNECT_TIMEOUT=5`, which makes every connection give up after five seconds, and
an action for the real application: a connect timeout in its driver's configuration, and a statement
timeout for the queries, both shorter than anything a customer would wait for.

That is what a rehearsal is for. Nothing in lessons 16 to 19 predicted this one; it appeared the first
time the whole chain was made to fail together.
