---
title: The timeline, from what was left on disk
version: 1
---

Memory is the worst source for a timeline: it is confident, and it puts things in the order they
made sense rather than the order they happened. Logs and records have the times. Collect them:

```
ana@vm:~$ grep -h -E "promoted self|acquired session lock" ~/patroni/pg2.log ~/patroni/pg3.log
2026-10-16 02:47:59,585 INFO: promoted self to leader by acquiring session lock
ana@vm:~$ curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^primary,pg'
primary,pg1,DOWN
primary,pg2,UP
primary,pg3,DOWN
ana@vm:~$ psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c "SELECT count(*) FROM orders WHERE id > 50000"
14
```

Patroni's log on `pg2` gives the promotion to the millisecond. HAProxy's status page confirms where
port 5000 sends connections now. And the shop's own table settles the most important number: **14
orders arrived, exactly as many as `orders.sh` reported `ok`**. Nothing the application was told was
saved has gone missing, and nothing it was told failed was saved after all.

Put together:

| time | event | source |
|---|---|---|
| 02:47:32 | `pg1` killed (its machine "died") | the running note |
| 02:47:35 | first order fails | `orders.log` |
| 02:47:59.585 | `pg2` takes the leader key and promotes itself | Patroni's log on `pg2` |
| 02:48:01 | last order fails | `orders.log` |
| 02:48:02 | first order succeeds, on `pg2` | `orders.log` |

**Thirty seconds without orders**, from 02:47:32 to 02:48:02, and of those, about 27 waiting for the
leader key to expire and three for HAProxy to notice the new primary. That split is the useful part:
it says which knob each second belongs to, lesson 16's `ttl` or lesson 19's checks, and so which change
would shorten the next one, and at what risk.

Last, the recovery the decision section left open, done once its cause is understood: start `pg1`'s
Patroni again.

```
ana@vm:~$ patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697137969997383883) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Replica | streaming |  2 |         0 |
| pg2    | 127.0.0.1:5442 | Leader  | running   |  2 |           |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  2 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

`pg1` is a replica on timeline 2. The incident is over when that line says so, not when the shop took
its first order again, and the time of this line is the last entry in the timeline.
