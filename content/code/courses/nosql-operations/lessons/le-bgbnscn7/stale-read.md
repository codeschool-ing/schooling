---
title: A stale read, on purpose
version: 1
---

This lesson needs four containers: lesson 1's three, started empty, and a second Redis that copies
the first. If earlier lessons' containers are still there, remove them with
`docker rm -f mongo redis cassandra`. Then these five lines make everything, and the first fails
harmlessly if the network already exists:

```sh
docker network create nosql
docker run -d --name redis --network nosql redis:7.4
docker run -d --name redis-replica --network nosql redis:7.4 redis-server --replicaof redis 6379
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

The third line is the new one. `redis-server --replicaof redis 6379` starts a Redis that connects to
the container called `redis` and **copies every write the primary receives**, a moment
later. Lesson 15 is about Redis replication properly: how the copy starts, what it costs and what
happens when the primary dies. This section needs only the fact that the replica answers reads.

## Two copies that agree

```
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_host|master_link_status)"
role:slave
master_host:redis
master_link_status:up
ana@vm:~$ docker exec redis redis-cli SET stock:MN-330 1
OK
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
1
```

`role:slave` is Redis's own word for a replica, kept in `INFO` for compatibility. The link to the
primary is `up`, and a value written on the primary is on the replica by the time the next command
is typed.

## Pull the cable

`docker network disconnect` takes the replica off the `nosql` network: the container keeps running,
and it can no longer reach the primary. That is a partition, made with one command:

```
ana@vm:~$ docker network disconnect nosql redis-replica
ana@vm:~$ docker exec redis redis-cli SET stock:MN-330 0
OK
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
1
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status)"
role:slave
master_link_status:up
ana@vm:~$ docker exec redis-replica redis-cli CONFIG GET replica-serve-stale-data
replica-serve-stale-data
yes
ana@vm:~$ docker exec redis-replica redis-cli CONFIG GET repl-timeout
repl-timeout
60
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status|master_link_down_since_seconds)"
role:slave
master_link_status:down
master_link_down_since_seconds:0
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
1
```

The primary accepted the new stock, 0. The replica, asked a moment later, answered **1**, the value
from before, with nothing in the answer to say it might be out of date. Look at the first `INFO`:
the replica still reported its link as `up`. It does not know yet. A replica notices a silent primary
only when nothing has arrived for `repl-timeout` seconds, 60 by default, and the second `INFO`,
taken once the replica had given up, shows `master_link_status:down`.

**Even then it keeps answering.** `replica-serve-stale-data` is `yes` by default, so a replica that
knows it is cut off still serves what it has, and the last `GET` still says 1. Set to `no`, the
replica would refuse most commands with an error instead. That setting is the CAP choice of lesson 1
in one line of configuration: answer and possibly be wrong, or refuse.

## Put it back

```
ana@vm:~$ docker network connect nosql redis-replica
ana@vm:~$ docker exec redis-replica redis-cli GET stock:MN-330
0
ana@vm:~$ docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status)"
role:slave
master_link_status:up
```

A few seconds after `docker network connect`, the replica had reconnected, caught up and answered
0. **That is the "eventual" in eventual consistency**: once the copies can talk again, they agree.
What the term does not say is how long that takes, and in between, for a minute here, the replica gave
an answer that an application would have shown to a customer as the truth: one monitor in stock.
