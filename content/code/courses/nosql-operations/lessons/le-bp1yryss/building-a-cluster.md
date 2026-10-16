---
title: Building a cluster on one machine
version: 1
---

A production cluster spreads these servers over many machines, and each shard and the config server
is a replica set of three. **The lab's cluster has the same parts at the smallest size that still
behaves like a cluster**: one config server, two shards and one `mongos`, each in its own container
on the `nosql` network, and each replica set with a single member.

## What this lesson needs

The `nosql` network from lesson 1, and the memory lesson 9's replica set was using. Stop its three
members first, with the thirty seconds lesson 9 gave them:

```sh
docker stop -t 30 mongo1 mongo2 mongo3
```

## The script

Five servers started by hand is twenty lines typed in the right order, so this lesson keeps them in
a script. Save it as `cluster.sh` in your home directory on the VM:

```schooling-example
{"language": "sh", "file": "cluster.sh", "parts": [{"code": "#!/bin/sh\n# cluster.sh: a sharded MongoDB cluster on one machine, for practice only.\nset -e\n", "note": "The `set -e` line stops the script at the first command that fails, so a half-built cluster says so instead of carrying on."}, {"code": "start() {  # start NAME COMMAND...: one container on the nosql network\n  name=$1; shift\n  docker run -d --name \"$name\" --hostname \"$name\" --network nosql mongo:8.0 \"$@\" >/dev/null\n}\n", "note": "Every server is the same image with a different command, the way lesson 9 started its members. The container id `docker run` prints is thrown away to keep the output short."}, {"code": "wait_for() {  # wait until the server in container $1 answers\n  until docker exec \"$1\" mongosh --quiet --eval 'db.runCommand({ ping: 1 })' >/dev/null 2>&1; do sleep 1; done\n}\n", "note": "A server takes a second or two to listen. The script asks once a second instead of guessing how long to sleep."}, {"code": "initiate() {  # initiate NAME SET [EXTRA]: a replica set of one member\n  docker exec \"$1\" mongosh --quiet --eval \"rs.initiate({ _id: '$2', $3 members: [{ _id: 0, host: '$1:27017' }] }).ok\"\n  until docker exec \"$1\" mongosh --quiet --eval 'db.hello().isWritablePrimary' | grep -q true; do sleep 1; done\n}\n", "note": "In a sharded cluster every shard and the config server are replica sets, even with one member. One member keeps the lab small; a real cluster gives each set three, for lesson 9's reasons. The loop waits for the member to win its own election."}, {"code": "start cfg1 mongod --configsvr --replSet cfg --port 27017 --bind_ip_all --wiredTigerCacheSizeGB 0.25\nstart shard1 mongod --shardsvr --replSet shard1 --port 27017 --bind_ip_all --wiredTigerCacheSizeGB 0.25\nstart shard2 mongod --shardsvr --replSet shard2 --port 27017 --bind_ip_all --wiredTigerCacheSizeGB 0.25\nfor c in cfg1 shard1 shard2; do wait_for $c; done\ninitiate cfg1 cfg 'configsvr: true,'\ninitiate shard1 shard1\ninitiate shard2 shard2\n", "note": "`--configsvr` and `--shardsvr` say which job the server does; both would pick a port of their own, and `--port 27017` keeps the one every other lesson uses. `--wiredTigerCacheSizeGB 0.25` caps each server's cache at a quarter of a gigabyte, because by default each would size it from the memory of the whole machine."}, {"code": "start mongos mongos --configdb cfg/cfg1:27017 --bind_ip_all\nwait_for mongos\ndocker exec mongos mongosh --quiet --eval 'sh.addShard(\"shard1/shard1:27017\").shardAdded'\ndocker exec mongos mongosh --quiet --eval 'sh.addShard(\"shard2/shard2:27017\").shardAdded'\n", "note": "`mongos` stores nothing. It reads the cluster's map from the config server named in `--configdb`, and `sh.addShard` writes each shard into that map, as a replica set name followed by a member."}]}
```

Run it with `sh`. `time` in front measures how long the whole cluster takes to come up:

```
ana@vm:~$ time sh cluster.sh
1
1
1
shard1
shard2

real	0m16.371s
user	0m0.416s
sys	0m0.251s
```

The three `1` lines are the three `rs.initiate` calls succeeding, and the two names are
`sh.addShard` reporting the shards it added. Under twenty seconds from nothing to a cluster.

## Asking the cluster what it is

Every command from here on goes to `mongos`, as an application's would. `sh.status()` reads the map
from the config server and prints it:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet
[direct: mongos] test> sh.status()
shardingVersion
{ _id: 1, clusterId: ObjectId('6acaea8cf7ad0a561ad12413') }
---
shards
[
  {
    _id: 'shard1',
    host: 'shard1/shard1:27017',
    state: 1,
    topologyTime: Timestamp({ t: 1791683224, i: 10 }),
    replSetConfigVersion: Long('-1')
  },
  {
    _id: 'shard2',
    host: 'shard2/shard2:27017',
    state: 1,
    topologyTime: Timestamp({ t: 1791683224, i: 28 }),
    replSetConfigVersion: Long('-1')
  }
]
---
active mongoses
[ { '8.0.32': 1 } ]
---
autosplit
{ 'Currently enabled': 'yes' }
---
balancer
{
  'Currently enabled': 'yes',
  'Failed balancer rounds in last 5 attempts': 0,
  'Currently running': 'no',
  'Migration Results for the last 24 hours': 'No recent migrations'
}
---
shardedDataDistribution
[]
---
databases
[
  {
    database: { _id: 'config', primary: 'config', partitioned: true },
    collections: {}
  }
]
[direct: mongos] test> exit
```

Two shards, each named by its replica set and its one member. One `mongos`, running 8.0.32. A
**balancer** that is enabled and idle, with no migrations, because nothing has been sharded yet:
`databases` lists only `config`, the cluster's own metadata. The next section gives it a
collection.

The four containers used about 580 MB between them once they hold this lesson's data, as the last
command of the lesson measures. Stop them between sessions with `docker stop cfg1 shard1 shard2
mongos`, and start them again in the same order.
