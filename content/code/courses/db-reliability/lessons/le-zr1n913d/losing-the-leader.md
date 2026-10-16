---
title: Losing the leader
version: 1
---

Kill `pg1` as a dead machine would: its Patroni first, then its PostgreSQL, both with `kill -9`, so
that nothing is cleaned up. The `[.]` in the pattern makes it match `pg1.yml` without matching the
`pkill` command line itself. Then ask what the cluster believes:

```
ana@vm:~$ date +%T
01:39:37
ana@vm:~$ pkill -9 -f 'patroni/pg1[.]yml'; kill -9 $(head -n 1 ~/patroni/pg1/postmaster.pid)
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ date +%T
01:40:22
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ grep -h -E "promoted self|acquired session lock" ~/patroni/pg2.log ~/patroni/pg3.log
2026-10-16 01:40:05,976 INFO: promoted self to leader by acquiring session lock
```

Straight after the kill, **nothing has changed**: `pg1` is still `Leader` and `running`, because the
leader key has not expired and the `members/pg1` entry is the last one `pg1` wrote. Forty-five seconds
later `pg3` is the leader, on timeline 2, and `pg2` follows it; `pg1` has dropped off the list,
since its entry in etcd expired with it. The log says when: 01:40:05, **28 seconds after the kill**,
which is the key's 30-second `ttl` counted from its last renewal before the kill.

`pg3` won and not `pg2`. Both were current, so either was allowed, and etcd gave the key to whichever
asked first. Which one wins is not something to depend on.

That is the price of the decision being safe: **for up to `ttl` seconds after a primary dies,
nothing accepts writes**, because the only alternative is to promote before the old leader's claim
has run out. A shorter `ttl` fails over sooner and is more easily fooled by a primary that is only
slow, which is lesson 13's measurement problem again.

## The dead node comes back

Start `pg1`'s Patroni again, as a machine reboot would:

```
ana@vm:~$ patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  2 |         0 |
| pg3    | 127.0.0.1:5443 | Leader  | running   |  2 |           |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ grep -E "rewind" ~/patroni/pg1.log | head -n 3
2026-10-16 01:40:23,884 INFO: running pg_rewind from pg3
2026-10-16 01:40:23,940 INFO: running pg_rewind from dbname=postgres user=postgres host=127.0.0.1 port=5443 target_session_attrs=read-write
2026-10-16 01:40:24,744 INFO: pg_rewind exit code=0
```

Lesson 15's reboot made a second primary. This one came back as a **replica**, on timeline 2,
streaming from `pg3`. Before starting PostgreSQL, Patroni read the leader key and saw it named another
node. Then it ran **`pg_rewind`** to bring `pg1`'s data back to the point where the histories split,
with the checksums `initdb` turned on and the configuration it knows where to find. Everything lesson 15 did
by hand to rejoin a primary, in under a second of the log.
