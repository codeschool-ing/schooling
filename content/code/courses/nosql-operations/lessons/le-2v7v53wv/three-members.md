---
title: Three members, one primary
version: 1
---

A replica set looks like three databases that copy each other, and it is not. **It is one database
kept in three copies, and exactly one copy takes writes.** That copy is the **primary**. The other
two are **secondaries**: they copy what the primary did, in the order it did it, and either can
take its place when it goes.

Three is the smallest number that works. With two copies, a member that stops hearing its partner
cannot tell a dead partner from a cut cable, which is lesson 1's partition with nobody to break the
tie. With three, any two are a **majority**, and a majority is what every decision in this lesson
rests on: who is primary, which writes count as safe, and which side of a broken network keeps
working.

## What this lesson needs

The `nosql` network from lesson 1, and three new containers. Stop the single `mongo` from lesson 1
to give the VM its memory back, and create the network if this machine never had it:

```sh
docker stop mongo
docker network create nosql
```

If the network already exists, the second line fails and nothing else changes.

## Three servers that know they belong to a set

```sh
docker run -d --name mongo1 --hostname mongo1 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
docker run -d --name mongo2 --hostname mongo2 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
docker run -d --name mongo3 --hostname mongo3 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
```

Everything after `mongo:8.0` replaces the image's default command, so each container runs `mongod`
with two settings of its own. `--replSet rs0` names the set the server belongs to. `--bind_ip_all`
makes it listen on the network as well as on `127.0.0.1`, which is all `mongod` listens on by
default; without it the other two could not reach it. `--hostname` gives each container the same
name inside as on the network, so that every answer naming a host says `mongo1` rather than a
container id.

```
ana@vm:~$ docker run -d --name mongo1 --hostname mongo1 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
c8956ec01b97034f5a583e53dde98bf01a26d6d4b3fd8cf34b96148278a06f4e
ana@vm:~$ docker run -d --name mongo2 --hostname mongo2 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
1c02c81c47b9f936f9d7f23147b5f8a1489b201b72217470efb6e04d016c9952
ana@vm:~$ docker run -d --name mongo3 --hostname mongo3 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
26bbba0ee053f30c285ba22b47fdd06d417f4f8632fd76fa024b273c61b62a1e
```

## Forming the set

Three servers started with `--replSet` are not a set yet: each waits to be told who the others
are. `rs.initiate` tells one of them, naming every member by the name the network resolves, and
that member passes the configuration on to the rest:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet
test> rs.initiate({ _id: "rs0", members: [ { _id: 0, host: "mongo1:27017" }, { _id: 1, host: "mongo2:27017" }, { _id: 2, host: "mongo3:27017" } ] })
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791618858, i: 1 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791618858, i: 1 })
}
rs0 [direct: secondary] test> rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))
[
  { name: 'mongo1:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo2:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
rs0 [direct: primary] test> exit
```

**The prompt is the first thing to read.** Right after `rs.initiate`, `mongo1` called itself
`[direct: secondary]`: every member starts as a secondary, and the set holds its first election
among them. The capture waited fifteen seconds before the next line, and by then `mongo1` had won
and the prompt said `primary`. `direct:` means `mongosh` is talking to this one member rather than
to the set, a difference that matters in the section on read preference.

`rs.status()` on its own prints a couple of hundred lines per call. The `map` at the end keeps
three fields of each member: its name, its state, and `health`, which is 1 when this member's last
heartbeat to it was answered. **Every field is what the member you asked believes**, built from
heartbeats sent every two seconds. In the last section of this lesson two members answer the same
question differently, and both are telling the truth as they see it.
