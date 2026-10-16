---
title: A primary and two replicas
version: 1
---

Lesson 13 made Redis survive a restart. **A replica makes it survive the loss of the machine**: a
second Redis that receives every write the first one makes and can take its place. Redis replication
is simple to start, one option on the replica, and it has one property that the rest of this lesson
turns on: **the primary answers the client first and sends the write to its replicas afterwards.**

## Three containers

The single `redis` container of the previous lessons goes; three take its place, on the same
network, so that each finds the others by name:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis-1 --network nosql redis:7.4 redis-server --replica-announce-ip redis-1
68e9c00965b15a1da48039c7cd353f2f6241cca9b3a4854b55f6c0ff5b7d4ea2
ana@vm:~$ docker run -d --name redis-2 --network nosql redis:7.4 redis-server --replica-announce-ip redis-2 --replicaof redis-1 6379
03ff9650a9d3a678b668c41ebe9326b9212287d9ad14880045939c0be93bd4d3
ana@vm:~$ docker run -d --name redis-3 --network nosql redis:7.4 redis-server --replica-announce-ip redis-3 --replicaof redis-1 6379
c44e395338bfb8433b30acddeff346f1c4e52588a6b21bfc0e7e29ae5eba3cb6
```

`--replicaof redis-1 6379` makes a server a replica of the one at that address: it connects, receives
a full copy of the dataset and then every write as it happens. `--replica-announce-ip` gives each
server the name the others should use for it. Without it a replica is known by its address inside
Docker's network, which works and is harder to read in the sections to come.

## What each one says about itself

```
ana@vm:~$ docker exec redis-1 redis-cli INFO replication | grep -E "^(role|connected_slaves|slave[0-9]|master_repl_offset):"
role:master
connected_slaves:2
slave0:ip=redis-2,port=6379,state=online,offset=0,lag=0
slave1:ip=redis-3,port=6379,state=online,offset=0,lag=0
master_repl_offset:0
ana@vm:~$ docker exec redis-2 redis-cli INFO replication | grep -E "^(role|master_host|master_link_status|slave_repl_offset|slave_read_only):"
role:slave
master_host:redis-1
master_link_status:up
slave_repl_offset:0
slave_read_only:1
```

The primary counts two replicas, `online`, and the **replication offset**: the number of bytes of
writes it has produced since the replication stream began. Each replica reports the offset it has
received. When the two numbers are equal the replica has everything; the difference, when there is
one, is how far behind it is. And a replica is **read-only** by default:

```
ana@vm:~$ docker exec redis-1 redis-cli SET order:1001 paid
OK
ana@vm:~$ docker exec redis-2 redis-cli GET order:1001
paid
ana@vm:~$ docker exec redis-2 redis-cli SET order:1002 paid
READONLY You can't write against a read only replica.
```

The write to the primary reached the replica, which answered it on a read; the write to the replica
was refused with `READONLY`. A replica that accepted writes would hold data its primary never saw, and
the next full copy from the primary would erase it.

## Asynchronous by design

The primary does not wait for its replicas before answering. Two hundred thousand writes, in one
`EVAL`, and the two servers counted straight away:

```
ana@vm:~$ docker exec redis-1 redis-cli EVAL "for i = 1, 200000 do redis.call('SET', 'page:' .. i, 'x') end" 0 > /dev/null; docker exec redis-1 redis-cli DBSIZE; docker exec redis-2 redis-cli DBSIZE
200001
200001
ana@vm:~$ docker exec redis-2 redis-cli DBSIZE
200001
```

Both counted 200,001 at once, and the replica again a moment later. On one machine, over Docker's own
network, the replica had caught up before the next command even started. **The gap exists, and here it was
too short to see.** Between two machines it is at least a network round trip, and the next two
sections make it long on purpose.

**That gap is the cost of the speed**, and it is the PA/EL of lesson 1. The primary answers at once and replicates in the background, so a read from a replica can be behind, and a write the primary has
acknowledged can exist nowhere else for a moment. Usually the moment is milliseconds. Two sections on,
it is long enough to lose an order.

Replication is also not a backup. A `FLUSHALL` on the primary reaches every replica in the same
milliseconds, and a key deleted by mistake is deleted everywhere. Lesson 13's files, kept somewhere
else, are the backup.
