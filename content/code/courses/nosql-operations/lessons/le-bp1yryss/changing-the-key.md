---
title: The key you cannot change later, and what changing it costs now
version: 1
---

For most of MongoDB's history the title of this lesson was literally true. The shard key was fixed
when the collection was sharded, and changing it meant creating a new collection with the new key,
copying every document across and switching the application over. **That changed in two steps,
and neither made it cheap.**

| version | command | what it does |
|---|---|---|
| 4.4 | `refineCollectionShardKey` | adds fields to the **end** of the existing key; nothing moves |
| 5.0 | `reshardCollection` | any new key; the whole collection is copied to its new places |
| 8.0 | `unshardCollection`, `moveCollection` | turn a sharded collection back into an unsharded one, or move an unsharded one to another shard; not run here |

## Refining: cheap, and only one direction

The single-valued key from the last section can be refined into `{ country: 1, visitId: 1 }`,
because the new key starts with the old one. It needs an index on the new key first:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> function ranges(coll) { const uuid = db.getSiblingDB("config").collections.findOne({ _id: "shop." + coll }).uuid; db.getSiblingDB("config").chunks.find({ uuid }).sort({ min: 1 }).forEach(c => print(c.shard, EJSON.stringify(c.min), EJSON.stringify(c.max), c.jumbo ? "jumbo" : "")) }
[Function: ranges]
[direct: mongos] shop> db.visits_by_country.createIndex({ country: 1, visitId: 1 })
country_1_visitId_1
[direct: mongos] shop> db.adminCommand({ refineCollectionShardKey: "shop.visits_by_country", key: { country: 1, visitId: 1 } }).ok
1
[direct: mongos] shop> ranges("visits_by_country")
shard2 {"country":{"$minKey":1},"visitId":{"$minKey":1}} {"country":"BR","visitId":11154} 
shard2 {"country":"BR","visitId":11154} {"country":"BR","visitId":22308} 
shard2 {"country":"BR","visitId":22308} {"country":"BR","visitId":33462} 
shard1 {"country":"BR","visitId":33462} {"country":{"$maxKey":1},"visitId":{"$maxKey":1}} 

[direct: mongos] shop> spread("visits_by_country")
[
  { shard: 'shard2', owned: 33462, orphaned: 0 },
  { shard: 'shard1', owned: 66538, orphaned: 33462 }
]
[direct: mongos] shop> exit
```

The refine itself changed only the map: every existing range now also carries `visitId` bounds.
**What it bought was the ability to split.** Ninety seconds later the balancer had split the
formerly indivisible range and moved three pieces to `shard2`, exactly as it did for `visits`,
which was sharded on that key from the start. Refining cannot remove a field, reorder fields, or
change the first field. It mends a key that is too coarse, and nothing else.

## Resharding: anything, at the price of a full copy

`orders` was sharded on the growing `orderId` in the section on the shard key, and every new order
lands on one shard. Refining cannot help: adding a field after `orderId` still sorts by `orderId`
first. **`reshardCollection` takes a whole new key** and rebuilds the collection under it:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> const started = Date.now()

[direct: mongos] shop> db.adminCommand({ reshardCollection: "shop.orders", key: { orderId: "hashed" } }).ok
1
[direct: mongos] shop> (Date.now() - started) / 1000
332.94
[direct: mongos] shop> spread("orders")
[
  { shard: 'shard1', owned: 9859, orphaned: 0 },
  { shard: 'shard2', owned: 10141, orphaned: 0 }
]
[direct: mongos] shop> db.orders.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
SHARD_MERGE
[direct: mongos] shop> exit
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" cfg1 shard1 shard2 mongos
NAME      MEM USAGE / LIMIT
cfg1      127.8MiB / 15.72GiB
shard1    221.4MiB / 15.72GiB
shard2    188.2MiB / 15.72GiB
mongos    46.66MiB / 15.72GiB
```

It took **332.94 seconds** for 20,000 small orders, five and a half minutes. That number is mostly
not work: by default resharding spends at least five minutes copying, so that the shards have time
to catch up with the writes that arrive during the copy, and on a real collection the copy itself
then dominates. Afterwards the orders were spread 9,859 and 10,141, the same split the hashed
collection got, and a range of order numbers became a `SHARD_MERGE` query, the price the shard-key section
showed for a hashed key.

What resharding does underneath is the old manual procedure, automated. Each shard builds the
collection again under the new key, copying every document to the shard the new key assigns and
applying the writes that arrive meanwhile. At the end the cluster blocks writes to the collection
for a short moment while it switches over. **It needs free disk for a second copy of
the collection on the shards, and it puts the load of moving all of it on a cluster that is
probably resharding because it was already struggling.**

So "the key you cannot change later" is now "the key that costs a full copy to change later". The
choice made on the first day is still the one the cluster lives with, unless you pay for another
one; the access pattern of lesson 3 is what you choose it from.
