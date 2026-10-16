---
title: A switchover in one command
version: 1
---

The planned move is one command, naming the current leader and the node to hand it to:

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml switchover --leader pg3 --candidate pg1 --force
Current cluster topology
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
2026-10-16 01:40:57.53320 Successfully switched over to "pg1"
+ Cluster: shop (7697120517756803320) --------+----+-----------+
| Member | Host           | Role    | State   | TL | Lag in MB |
+--------+----------------+---------+---------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running |  2 |           |
| pg2    | 127.0.0.1:5442 | Replica | running |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | stopped |    |   unknown |
+--------+----------------+---------+---------+----+-----------+
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  3 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  3 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  3 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

`patronictl` printed the topology it found, did the switchover lesson 15 did by hand (a clean stop
of `pg3`, then promoting `pg1` once it had everything), and printed the topology a moment later: `pg3`
still `stopped` while it restarted as a replica. A few seconds after that, everything is
`streaming` on timeline 3, with `pg1` the leader again.

Lesson 23 rehearses exactly this, and it is the first thing to try on any new cluster: a switchover
that works says **the replicas are current**, that every node can reach every other, and that the
application, lesson 19's subject, follows the leader.
