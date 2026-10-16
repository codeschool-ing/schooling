---
title: A rehearsal that refuses to start
version: 1
---

Test the abort first, on purpose. Stop `pg3` cleanly, so that the cluster is down to two nodes, and run
the rehearsal:

```
ana@vm:~$ pkill -TERM -f 'patroni/pg3[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697144668418349739) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | stopped   |    |   unknown |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ ./rehearsal.sh; echo "exit $?"
ABORT: 3 members, 2 healthy, lag 999 MB, leader pg1
exit 1
```

`pg3` is `stopped`, its lag `unknown`, and the script **refused**, with exit status 1, before it touched
anything: two healthy members out of three, and a lag it could not read, counted as 999. Killing the
leader now would have left one node, and the next failure of anything would have stopped the shop.

The lag counted as 999 is a decision written into the script after it was wrong. Its first version
read `patronictl`'s lag as a number, met the word `unknown`, and the line of Python failed and printed
nothing. The shell's checks then compared empty strings, complained, and **carried on**: it started
`orders.sh`, tried to kill a leader whose name it no longer had, and reported a healthy run. A guard
that fails open is worse than none, because it is believed. The version above stops on anything it
cannot read, which is the only safe reading of "I do not know".

Make the cluster whole again before the real run:

```
ana@vm:~$ patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697144668418349739) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```
