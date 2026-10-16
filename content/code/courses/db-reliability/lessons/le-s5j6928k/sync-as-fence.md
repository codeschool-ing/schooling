---
title: Synchronous replication as a fence
version: 1
---

The last row of the table needs no extra machinery, and the cluster from this lesson can show it,
once a switchover with lesson 16's one command has made `pg1` the leader again.
Patroni's `synchronous_mode` manages lesson 12's `synchronous_standby_names` for you: it picks one
replica as the **synchronous standby**, and the leader waits for it on every commit.

```
ana@vm:~$ patronictl -c ~/patroni/pg1.yml edit-config --set synchronous_mode=true --force > /dev/null
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697125163435731023) ---+-----------+----+-----------+
| Member | Host           | Role         | State     | TL | Lag in MB |
+--------+----------------+--------------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader       | running   |  3 |           |
| pg2    | 127.0.0.1:5442 | Replica      | streaming |  3 |         0 |
| pg3    | 127.0.0.1:5443 | Sync Standby | streaming |  3 |         0 |
+--------+----------------+--------------+-----------+----+-----------+
```

`pg3` is the `Sync Standby`. Now freeze `pg1`'s Patroni again, and try the same write on the old
primary once the failover has happened:

```
ana@vm:~$ pkill -STOP -f 'patroni/pg1[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697125163435731023) ---+-----------+----+-----------+
| Member | Host           | Role         | State     | TL | Lag in MB |
+--------+----------------+--------------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Sync Standby | streaming |  4 |         0 |
| pg3    | 127.0.0.1:5443 | Leader       | running   |  4 |           |
+--------+----------------+--------------+-----------+----+-----------+
ana@vm:~$ timeout 10 psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (73, 7300, now()) RETURNING id"; echo "exit $?"
exit 124
ana@vm:~$ psql -h 127.0.0.1 -p 5441 -U postgres -XAt shop -c "SHOW synchronous_standby_names"
pg3
ana@vm:~$ pkill -CONT -f 'patroni/pg1[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697125163435731023) ---+-----------+----+-----------+
| Member | Host           | Role         | State     | TL | Lag in MB |
+--------+----------------+--------------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica      | streaming |  4 |         0 |
| pg2    | 127.0.0.1:5442 | Sync Standby | streaming |  4 |         0 |
| pg3    | 127.0.0.1:5443 | Leader       | running   |  4 |           |
+--------+----------------+--------------+-----------+----+-----------+
```

`pg3` became the leader, and `pg2` its synchronous standby. On `pg1` the insert **waited until
`timeout` gave up**, exit 124: its `synchronous_standby_names` still says `pg3`, and `pg3` is not its
standby any more. The old primary can still accept a connection and a statement, but it cannot
**confirm** a commit, so no application is told "saved" about a row only it has. When its Patroni
thawed, it rejoined as a replica as before.

Two limits keep this from being the whole answer. The waiting transaction is committed **locally**,
as lesson 12 showed with a cancel, so a careless cancel on the old primary turns it back into a lost
write. And it costs every commit a round trip to the standby. It is the cheapest fence available, and
the strongest designs combine it with the watchdog.
