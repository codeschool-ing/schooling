---
title: Detect and decide
version: 1
---

The cluster from lessons 16 to 19: three Patroni nodes with `pg1` the leader, HAProxy in front on port
5000, and lesson 19's `orders.sh` placing one order a second through it. Start the shop, and eight
seconds later kill the leader as a dead machine would, noting the time:

```
ana@vm:~$ ./orders.sh > orders.log 2>&1 &
ana@vm:~$ date +%T; pkill -9 -f 'patroni/pg1[.]yml'; kill -9 $(head -n 1 ~/patroni/pg1/postmaster.pid)
02:47:32
```

## Detect

Nothing in this lab paged anybody. What the customers saw is in `orders.log`:

```
ana@vm:~$ grep -c ok orders.log; grep -c FAILED orders.log
14
26
ana@vm:~$ grep -m 1 FAILED orders.log; grep FAILED orders.log | tail -n 1; grep -A 1 FAILED orders.log | tail -n 1
02:47:35 FAILED
02:48:01 FAILED
02:48:02 ok on 5442
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697137969997383883) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Leader  | running   |  2 |           |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  2 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

**26 orders failed and 14 went through.** The first failure was at 02:47:35, three seconds after the
kill; the last at 02:48:01; the next order, at 02:48:02, went to `pg2` on port 5442. And `patronictl`
shows `pg2` the leader on timeline 2, `pg3` following it, and `pg1` absent.

In a real shop the first sign would have been one of three things: an alert (lesson 13's check, or
HAProxy's primary changing), a customer, or an engineer who happened to be looking. Only the first is
a plan, and the write-up will ask which one it was.

## Decide

Patroni made the urgent decision by itself, half a minute after the kill. What is left for people is
everything it does not know:

- **Is it over?** The shop takes orders again. Is anything else still wrong, such as a replica too far
  behind, or a disk filling with the log a dead node's slot holds (lesson 11)?
- **What was lost?** Lesson 12's question: anything committed on `pg1` that `pg2` never received. With
  asynchronous replicas the honest answer comes from the positions, and the shop's own records.
- **What about `pg1`?** Bring it back now, or leave it down until somebody knows why its machine died.
  A node that failed for a reason not yet understood can fail again in the middle of the recovery.
- **Who needs to know?** Support, before the customers' messages arrive; the people responsible for the
  application, whose errors these were.

Each decision goes into the running note with its time. Deciding to wait is a decision, and is written
down like one.
