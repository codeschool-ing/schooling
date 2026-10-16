---
title: Three nodes and an etcd
version: 1
---

Install Patroni and etcd from Ubuntu's packages:

```sh
sudo apt install -y patroni etcd-server etcd-client
```

The `etcd-server` package starts etcd as a service at once, as a single member listening on
`localhost:2379`. Ask it whether it is healthy:

```
ana@vm:~$ etcdctl endpoint health
127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.645217ms
```

One etcd is enough to learn on and is **not** enough to run on: the last section of this lesson
stops it, and shows what that costs.

## The configuration

Each Patroni node is one PostgreSQL server plus the Patroni process that runs it. This course runs
three, as your own user, with their data directories under `~/patroni` and their ports 5441 to 5443,
next to the 16/main that Ubuntu runs on 5432. Patroni creates and starts these servers itself, with
`initdb` and `pg_ctl` from PostgreSQL's own directory, so `pg_lsclusters` will never list them.

Save this as `~/patroni/pg1.yml` after `mkdir -p ~/patroni`:

```schooling-example
{"language": "yaml", "file": "pg1.yml", "parts": [{"code": "scope: shop", "note": "The cluster's name. Every node with the same `scope` belongs to the same cluster, and the cluster's keys in etcd live under it."}, {"code": "name: pg1\n", "note": "This node's own name, which `patronictl` shows and which becomes its `application_name` when it replicates."}, {"code": "restapi:\n  listen: 127.0.0.1:8008\n  connect_address: 127.0.0.1:8008\n", "note": "Patroni's own HTTP interface. The other nodes, `patronictl` and lesson 19's load balancer ask each node about itself here."}, {"code": "etcd3:\n  hosts: 127.0.0.1:2379\n", "note": "Where the shared state lives: one etcd, through its version 3 interface."}, {"code": "bootstrap:\n  dcs:\n    ttl: 30\n    loop_wait: 10\n    retry_timeout: 10\n    maximum_lag_on_failover: 1048576\n    postgresql:\n      use_pg_rewind: true\n      use_slots: true", "note": "Used once, by the first node to start, to create the cluster. `ttl` is how long the leader's claim lasts without being renewed, `loop_wait` how often each node wakes up. A replica more than `maximum_lag_on_failover` bytes behind may not become the leader."}, {"code": "  initdb:\n  - encoding: UTF8\n  - data-checksums\n", "note": "Checksums at `initdb`, so that lesson 15's `pg_rewind` refusal cannot happen here."}, {"code": "postgresql:\n  listen: 127.0.0.1:5441\n  connect_address: 127.0.0.1:5441\n  data_dir: /home/ana/patroni/pg1\n  bin_dir: /usr/lib/postgresql/16/bin", "note": "The PostgreSQL this node runs: its address, its data directory, and the programs Ubuntu installed."}, {"code": "  parameters:\n    unix_socket_directories: /home/ana/patroni", "note": "The socket goes in your home directory, since `/var/run/postgresql` belongs to the `postgres` user and these servers run as you."}, {"code": "  pg_hba:\n  - local all all trust\n  - host replication replicator 127.0.0.1/32 scram-sha-256\n  - host all all 127.0.0.1/32 scram-sha-256", "note": "Patroni writes `pg_hba.conf` from this list. The socket needs no password, because it sits in your home directory, which Ubuntu lets nobody else enter; connections over the network, replication included, need one."}, {"code": "  authentication:\n    replication:\n      username: replicator\n      password: replica-pass-1\n    superuser:\n      username: postgres\n      password: patroni-pass-1", "note": "The two roles Patroni creates at bootstrap and uses afterwards: one to replicate, one to administer, including `pg_rewind`."}]}
```

**Change `ana` to your own user name** in `data_dir` and `unix_socket_directories`. The other two
nodes differ only in their name, their two ports and their directory, so make them from the first
with `sed` rather than by hand:

```
ana@vm:~$ sed -e 's/pg1/pg2/g' -e 's/8008/8009/g' -e 's/5441/5442/g' ~/patroni/pg1.yml > ~/patroni/pg2.yml
ana@vm:~$ sed -e 's/pg1/pg3/g' -e 's/8008/8010/g' -e 's/5441/5443/g' ~/patroni/pg1.yml > ~/patroni/pg3.yml
ana@vm:~$ grep -E "name:|listen:|data_dir:" ~/patroni/pg3.yml
name: pg3
  listen: 127.0.0.1:8010
  listen: 127.0.0.1:5443
  data_dir: /home/ana/patroni/pg3
      username: replicator
      username: postgres
```

## Starting them

Patroni runs in the foreground and logs to its terminal. A packaged installation runs it as a
service; here, start each in the background with its log in a file, the first one alone, so that it
is the one that creates the cluster:

```
ana@vm:~$ patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &
ana@vm:~$ patroni ~/patroni/pg2.yml > ~/patroni/pg2.log 2>&1 &
ana@vm:~$ patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

`patronictl` reads the same file to find etcd, and `list` shows what etcd knows: **one leader and two
replicas, all `streaming`**, on timeline 1. `pg2` and `pg3` did not run `initdb`; they found a leader
in etcd and made themselves its replicas with a base backup, as lesson 11 did by hand.
