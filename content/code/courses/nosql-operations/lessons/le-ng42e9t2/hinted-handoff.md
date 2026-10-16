---
title: Hinted handoff, the write kept for a node that is down
version: 1
---

Lesson 17 stopped a node and wrote at `QUORUM`, and the write succeeded with two replicas of three.
The obvious question is what happens to the third copy. **Cassandra does not forget it: the
coordinator keeps the write, as a hint, and hands it over when the node comes back.** That is the
first of three mechanisms that bring replicas back into agreement, and the cheapest.

This lesson uses the three nodes of lesson 16 with lesson 17's keyspace at three copies and its
`stock` table, with the four products in it. If you rebuilt the cluster, lessons 16 and 17 have the
commands; any four rows in `stock` will do.

## Before anything fails

```
ana@vm:~$ docker exec c1 nodetool statushandoff
Hinted handoff is running
ana@vm:~$ docker exec c1 nodetool getmaxhintwindow
Current max hint window: 10800000 ms
```

Hinted handoff is on by default, and `max_hint_window` is `10800000` ms, **three hours**: a
coordinator keeps hints for a node for its first three hours of being down. After that it stops
storing them, and a node that comes back later has to be brought up to date by repair.

## A node down, two writes

```
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> UPDATE shop.stock SET units = 11 WHERE sku = 'MS-204';
cqlsh> UPDATE shop.stock SET units = 39 WHERE sku = 'CB-012';
cqlsh> exit
ana@vm:~$ docker exec c1 ls -l /var/lib/cassandra/hints
total 4
-rw-r--r-- 1 cassandra cassandra 188 Oct 10 20:22 1fe37605-9cd6-4057-a79a-381f1eefc367-1791663760093-2.hints
ana@vm:~$ docker exec c1 nodetool listpendinghints
This node does not have any pending hints
ana@vm:~$ docker exec c1 nodetool status shop | grep -E "^(UN|DN)"
UN  172.18.0.3  85.08 KiB   16      100.0%            c91ac31c-cf75-4667-8186-4bce70e70e37  rack1
UN  172.18.0.2  108.01 KiB  16      100.0%            d2afca73-800d-4bc6-8139-86a18d5f752d  rack1
DN  172.18.0.4  119.66 KiB  16      100.0%            1fe37605-9cd6-4057-a79a-381f1eefc367  rack1
```

Two writes at `QUORUM` with `c3` stopped, both acknowledged by `c1` and `c2`. **The hints directory
on `c1` now holds a file**, and its name begins with `1fe37605-9cd6-…`, which is the host ID that
`nodetool status` shows for the `DN` node, `c3`. Each node keeps one series of hint files per node it
is holding writes for, and these 188 bytes are the two updates.

`nodetool listpendinghints` answered that there were none, while the file sat in the directory. It
reported nothing pending throughout this run; **the directory is the more reliable witness**, and the
hint files' names say whom they are for. That is worth knowing before an incident, when a tool that
says "nothing" is easy to believe.

## The node returns

```
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ docker logs c1 2>&1 | grep -E "Finished hinted handoff|Deleted hint file"
INFO  [HintsDispatcher:1] 2026-10-10T20:23:10,502 HintsStore.java:232 - Deleted hint file 1fe37605-9cd6-4057-a79a-381f1eefc367-1791663760093-2.hints
INFO  [HintsDispatcher:1] 2026-10-10T20:23:10,503 HintsDispatchExecutor.java:300 - Finished hinted handoff of file 1fe37605-9cd6-4057-a79a-381f1eefc367-1791663760093-2.hints to endpoint /172.18.0.4:7000: 1fe37605-9cd6-4057-a79a-381f1eefc367
ana@vm:~$ docker exec c1 ls -l /var/lib/cassandra/hints
total 0
```

Once `c3` was answering, `c1`'s log shows **`Finished hinted handoff of file … to
endpoint /172.18.0.4:7000`** and the file deleted, and the directory is empty again. `c3` now has the
two updates it missed, without anyone running anything.

## What hints do not cover

Hints are a convenience, not a guarantee, and four limits say why:

- **The window.** A node down longer than `max_hint_window` gets no hints for the time after it.
- **The coordinator.** Hints live on the node that coordinated the write. If that node is lost too,
  so are its hints.
- **Switched off.** `nodetool disablehandoff`, as lesson 18 used, or `hinted_handoff_enabled: false`
  in `cassandra.yaml`, means none are stored.
- **A slow replica that is not down.** A replica that is up but drops a write under load is not
  marked down, so it gets no hint for that write.

Each leaves a replica behind with nobody planning to tell it. The next two sections are the
mechanisms that find those differences: one by accident, during a read, and one on purpose.
