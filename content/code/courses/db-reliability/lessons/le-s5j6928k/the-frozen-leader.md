---
title: A leader that stops, and a database that does not
version: 1
---

The cluster from lesson 16, rebuilt, with `pg1` the leader:

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697125163435731023) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

`SIGSTOP` freezes a process where it stands, without killing it, the way a suspended virtual machine
is frozen. Freeze `pg1`'s Patroni, and nothing else, wait for the leader key to run out, and look:

```
ana@vm:~$ pkill -STOP -f 'patroni/pg1[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697125163435731023) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Leader  | running   |  2 |           |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  2 |         0 |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SELECT pg_is_in_recovery()"
f
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (71, 7100, now()) RETURNING id"
50001
INSERT 0 1
ana@vm:~$ psql -h 127.0.0.1 -p 5442 -U postgres -XAt shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (72, 7200, now()) RETURNING id"
50029
INSERT 0 1
```

The cluster did what lesson 16 said it would. `pg1` stopped renewing, its key expired, **`pg2` took it
and promoted itself** on timeline 2, and `pg3` follows `pg2`. As far as etcd knows, `pg1` is gone.

And `pg1`'s PostgreSQL is not in recovery. Nobody told it anything: the only process that could
demote it is frozen. An application server that still has a connection to port 5441 places order
**50001** there, and one that has moved to the new leader places order **50029** on `pg2`. **Two
primaries, both taking orders**, with every component working as designed.
