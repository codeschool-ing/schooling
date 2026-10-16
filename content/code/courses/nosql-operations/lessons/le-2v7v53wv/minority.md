---
title: The primary that loses its majority
version: 1
---

Lesson 1 promised to show the theorem happening, and this is MongoDB's half of that promise. A
crash is easy to reason about: the dead member is silent. **A partition is harder, because the
member cut off is alive, believes it is primary, and has clients still talking to it.** The rule
that settles it is the one this lesson started with: only a member that can reach a majority may
act as primary.

## Cutting the primary off

`docker network disconnect` takes a container off a network without stopping it. `docker exec`
does not travel over that network, so you can still type at the member that has been cut off. In
this run the primary was `mongo3`; use the name of yours:

```
ana@vm:~$ docker network disconnect nosql mongo3
ana@vm:~$ docker exec -it mongo3 mongosh --quiet shop
rs0 [direct: primary] shop> db.orders.insertOne({ _id: 1001, customer: "ana@example.com", sku: "MN-330", qty: 1 }, { writeConcern: { w: 1 } })
{ acknowledged: true, insertedId: 1001 }
rs0 [direct: primary] shop> rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))
[
  { name: 'mongo1:27017', state: '(not reachable/healthy)', health: 0 },
  { name: 'mongo2:27017', state: '(not reachable/healthy)', health: 0 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
rs0 [direct: secondary] shop> db.orders.insertOne({ _id: 1003, customer: "carla@example.com", sku: "CB-012", qty: 2 }, { writeConcern: { w: 1 } })
Uncaught 
MongoServerError[NotWritablePrimary]: not primary
rs0 [direct: secondary] shop> exit
```

The first insert, sent with `w: 1` in the second after the cable was cut, was **acknowledged**:
`mongo3` had not yet noticed anything. The capture then waited fifteen seconds before asking
again. By then `mongo3` had missed its heartbeats, seen that the only member it could reach
was itself, and **stepped down to `SECONDARY` on its own**. The next write was refused with
`not primary`.

That refusal is the consistency side of lesson 1's choice. A member that cannot reach a majority
cannot know whether the others have elected somebody else, so it stops taking writes rather than
risk a second history. Clients on its side of the cut get errors for as long as the partition
lasts.

## The other side

```
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: '(not reachable/healthy)', health: 0 }
]
ana@vm:~$ docker exec -it mongo2 mongosh --quiet shop
rs0 [direct: primary] shop> db.orders.insertOne({ _id: 1002, customer: "bruno@example.com", sku: "MN-330", qty: 1 })
{ acknowledged: true, insertedId: 1002 }
rs0 [direct: primary] shop> exit
```

The two members still connected saw `mongo3` as unreachable, held an election between themselves,
and `mongo2` won it. Bruno's order for the same monitor was written with the default write concern,
`majority`, which two connected members can satisfy.

## Healing, and the write that disappears

Reconnect `mongo3` and give it about fifteen seconds:

```
ana@vm:~$ docker network connect nosql mongo3
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
ana@vm:~$ docker exec mongo3 mongosh --quiet shop --eval 'db.orders.find()'
[ { _id: 1002, customer: 'bruno@example.com', sku: 'MN-330', qty: 1 } ]
ana@vm:~$ docker exec mongo3 find /data/db/rollback -name '*.bson'
/data/db/rollback/401e7bfa-7b2f-4bd4-a894-5a232c5c6843/removed.2026-10-10T07-56-28.0.bson
ana@vm:~$ docker exec mongo3 sh -c 'bsondump /data/db/rollback/*/removed.*.bson'
{"_id":{"$numberInt":"1001"},"customer":"ana@example.com","sku":"MN-330","qty":{"$numberInt":"1"}}
2026-10-10T07:56:44.989+0000	1 objects found
```

`mongo3` rejoined as a secondary, and **Ana's order is gone**. Only Bruno's is in the collection.
When `mongo3` came back, it compared its oplog with the new primary's, found the point where they
had diverged, and undid everything it had written after it. That is a **rollback**. The undone
documents are not deleted outright: they are saved to a BSON file under `/data/db/rollback`, which
`bsondump` turns back into JSON, and nothing applies them again unless a person does.

Ana's client had been told `acknowledged: true`. That was not a lie, because `w: 1` promises only
that the primary has the write, and the primary it reached turned out to be on the losing side. With
the default `w: "majority"` the same insert would have waited, failed when `mongo3` stepped down,
and Ana would have seen an error instead of an order that later vanished.

**Majority writes are what make the stepdown safe.** The minority refuses, the majority elects, and
any write that a majority acknowledged is on the side that keeps going. Lowering the write concern
to `w: 1` keeps the speed and gives up that last guarantee, and a rollback file nobody reads is
where the cost turns up.
