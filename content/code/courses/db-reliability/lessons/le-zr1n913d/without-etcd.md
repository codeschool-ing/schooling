---
title: When etcd is the one that fails
version: 1
---

Everything above rests on etcd answering. Stop it. On your machine that is `sudo systemctl stop
etcd`; the machine these transcripts come from has no `systemd`, and stops the same process with
`pkill`:

```
ana@vm:~$ sudo pkill -x etcd
ana@vm:~$ timeout 20 patronictl -c ~/patroni/pg1.yml list > /dev/null 2>&1; echo "exit $?"
exit 124
ana@vm:~$ grep -h -E "demot|read-only|failsafe" ~/patroni/pg1.log | tail -n 3
2026-10-16 01:40:25.234 -03 [14936] LOG:  database system is ready to accept read-only connections
2026-10-16 01:41:38,092 INFO: demoting self because DCS is not accessible and I was a leader
2026-10-16 01:41:39.711 -03 [15114] LOG:  database system is ready to accept read-only connections
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"
t
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (61, 6100, now())"
ERROR:  cannot execute INSERT in a read-only transaction
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  4 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  4 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  4 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

`patronictl` cannot list anything, and keeps retrying until `timeout` stops it. That is expected. The
next lines are the surprise: **the primary demoted itself.** `pg1` could not renew the leader key,
and the rule says that a leader that cannot renew must assume somebody else holds it. Every
PostgreSQL in the cluster is now read-only, and the shop cannot take an order, although all three
database servers are healthy. The last `list` above was taken after etcd was
started again (`sudo systemctl start etcd` on your machine; the same process, started by hand, on
this one): `pg1` took the key again, on timeline 4.

This is the trade the design makes, and it is the right one by default: a whole cluster that refuses
writes for a while is an outage; two primaries is lost data. It also means **etcd is part of the
database's availability**, and one etcd is a single point of failure for all three servers. In
production, etcd runs as **three or five members on separate machines**, so that losing one of them
changes nothing, and a majority is still there to agree.

## Failsafe mode

Patroni 3 offers a narrower rule. With `failsafe_mode` on, a leader that loses etcd asks the other
nodes directly, over their REST interfaces, and keeps running as the primary if **every** member
answers: if it can see all of them, none of them can have been promoted.

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml edit-config --set failsafe_mode=true --force
--- 
+++ 
@@ -1,3 +1,4 @@
+failsafe_mode: true
 loop_wait: 10
 maximum_lag_on_failover: 1048576
 postgresql:
Configuration changed
ana@vm:~$ sudo pkill -x etcd
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"
f
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (62, 6200, now())"
INSERT 0 1
ana@vm:~$ grep -h "failsafe" ~/patroni/pg1.log | tail -n 2
2026-10-16 01:43:45,893 INFO: continue to run as a leader because failsafe mode is enabled and all members are accessible
2026-10-16 01:43:55,901 INFO: continue to run as a leader because failsafe mode is enabled and all members are accessible
```

The same failure, and `pg1` stayed the primary and took the order. Every member had to answer for that
to happen; a node that is down, or cut off, ends it, and the leader demotes itself as before. It is a
setting for a cluster whose etcd is more likely to fail than its network, and it does not replace three
etcd members.
