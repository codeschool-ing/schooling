---
title: The first page, printed fresh
version: 1
---

The first thing anybody needs at the start of an incident is **the state of everything now**: which
node is the leader, where the proxy sends writes, what the slots hold, whether the consensus store
answers. Written on a page, that goes out of date the day after it is written. Printed by a script, it
is right every time it runs. Save this as `status.sh`, make it executable, and put its name at the top
of the runbook:

```schooling-example
{"language": "sh", "file": "status.sh", "parts": [{"code": "#!/bin/sh\n# status.sh: the first page of the runbook, printed fresh\necho \"== $(date '+%F %T %Z')\"", "note": "Each part prints a heading, so the output can be read by somebody who did not write the script."}, {"code": "echo \"== cluster\"\npatronictl -c ~/patroni/pg1.yml list", "note": "Who leads, who follows, and how far behind: lesson 16's view."}, {"code": "echo \"== port 5000 leads to\"\npsql -h 127.0.0.1 -p 5000 -U postgres -XAt shop \\\n  -c \"SELECT inet_server_port(), pg_is_in_recovery()\"", "note": "What the application actually reaches through lesson 19's HAProxy: the port behind port 5000, and whether it takes writes."}, {"code": "echo \"== slots on the leader\"\npsql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c \"\n  SELECT slot_name, active,\n         pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn))\n  FROM pg_replication_slots ORDER BY 1\"", "note": "Lesson 11's slots, and how much log each holds on the leader."}, {"code": "echo \"== etcd\"\netcdctl endpoint health 2>&1", "note": "Lesson 16's etcd: if this line is not healthy, nothing else on the page can change."}, {"code": "echo \"== pg_wal on each node\"\ndu -sh ~/patroni/pg*/pg_wal", "note": "The log on each node's disk, which is what fills first when something above is wrong."}]}
```

Run it:

```
ana@vm:~$ ./status.sh
== 2026-10-16 03:22:32 -03
== cluster
+ Cluster: shop (7697147027087042659) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
== port 5000 leads to
5441|f
== slots on the leader
pg2|t|0 bytes
pg3|t|0 bytes
== etcd
127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.468964ms
== pg_wal on each node
65M	/home/ana/patroni/pg1/pg_wal
49M	/home/ana/patroni/pg2/pg_wal
49M	/home/ana/patroni/pg3/pg_wal
```

Every line answers a question from lessons 11 to 19, in the order an incident asks them, and none of
it was typed by the person reading it. That is the property to keep: the runbook says **how to
look**, and the system says what is there.
