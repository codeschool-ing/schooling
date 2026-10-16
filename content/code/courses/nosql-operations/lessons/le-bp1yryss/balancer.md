---
title: Ranges, the balancer, and a key with one value
version: 1
---

The map a config server keeps is a list of **ranges**, older documentation calls them chunks, each
a stretch of shard-key values owned by one shard. Nothing guarantees that the ranges stay fair:
data arrives where the key sends it, and one shard fills faster than another. **The balancer is a
process on the config server that measures how much data each shard owns, per collection, and
moves ranges from the fullest to the emptiest** until the difference is small.

## Watching it move data

Since MongoDB 7.0 the balancer compares data size rather than counting ranges, and it only acts
when the gap between two shards passes about three times the collection's range size. The default
range size is 128 MB, far more than a lab collection holds, so `configureCollectionBalancing` sets
it to 1 MB for this one collection. Two more helpers join `spread`: `ranges` prints the map for a
collection, one line per range, with the word `jumbo` where the cluster has given up on a range;
`visits` writes 100,000 page views, all from Brazil, numbered by `visitId`. The key is
`{ country: 1, visitId: 1 }`:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> function ranges(coll) { const uuid = db.getSiblingDB("config").collections.findOne({ _id: "shop." + coll }).uuid; db.getSiblingDB("config").chunks.find({ uuid }).sort({ min: 1 }).forEach(c => print(c.shard, EJSON.stringify(c.min), EJSON.stringify(c.max), c.jumbo ? "jumbo" : "")) }
[Function: ranges]
[direct: mongos] shop> function visits(coll) { for (let b = 0; b < 10; b++) { const docs = []; for (let i = 0; i < 10000; i++) docs.push({ country: "BR", visitId: b * 10000 + i, sku: "MS-204", page: "/products/MS-204" }); db.getCollection(coll).insertMany(docs) } return db.getCollection(coll).countDocuments() }
[Function: visits]
[direct: mongos] shop> sh.shardCollection("shop.visits", { country: 1, visitId: 1 })
{
  collectionsharded: 'shop.visits',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683288, i: 39 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683288, i: 39 })
}
[direct: mongos] shop> db.adminCommand({ configureCollectionBalancing: "shop.visits", chunkSize: 1 }).ok
1
[direct: mongos] shop> visits("visits")
100000
[direct: mongos] shop> spread("visits")
[ { shard: 'shard1', owned: 100000, orphaned: 0 } ]
[direct: mongos] shop> spread("visits")
[
  { shard: 'shard2', owned: 33462, orphaned: 0 },
  { shard: 'shard1', owned: 66538, orphaned: 33462 }
]
[direct: mongos] shop> ranges("visits")
shard2 {"country":{"$minKey":1},"visitId":{"$minKey":1}} {"country":"BR","visitId":11154} 
shard2 {"country":"BR","visitId":11154} {"country":"BR","visitId":22308} 
shard2 {"country":"BR","visitId":22308} {"country":"BR","visitId":33462} 
shard1 {"country":"BR","visitId":33462} {"country":{"$maxKey":1},"visitId":{"$maxKey":1}} 

[direct: mongos] shop> exit
```

Right after the inserts, `shard1` owned all 100,000: the collection started as a single range on
the database's primary shard. The capture then waited ninety seconds. **By then the balancer had
split off three ranges of 11,154 visits each and moved them to `shard2`**, which owned 33,462.

The `orphaned` column is the other half of a move. A migration copies a range to its new shard,
switches ownership in the map, and only then deletes the old copy, after a delay of fifteen minutes
by default so that queries already running on the old shard can finish. Until then `shard1` still
holds 33,462 documents it no longer owns, and every count through `mongos` leaves them out.

## A key with a single value

Now the same 100,000 visits, sharded on `{ country: 1 }` alone. Every visit says `"BR"`, so the key
has **one value**:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function ranges(coll) { const uuid = db.getSiblingDB("config").collections.findOne({ _id: "shop." + coll }).uuid; db.getSiblingDB("config").chunks.find({ uuid }).sort({ min: 1 }).forEach(c => print(c.shard, EJSON.stringify(c.min), EJSON.stringify(c.max), c.jumbo ? "jumbo" : "")) }
[Function: ranges]
[direct: mongos] shop> function visits(coll) { for (let b = 0; b < 10; b++) { const docs = []; for (let i = 0; i < 10000; i++) docs.push({ country: "BR", visitId: b * 10000 + i, sku: "MS-204", page: "/products/MS-204" }); db.getCollection(coll).insertMany(docs) } return db.getCollection(coll).countDocuments() }
[Function: visits]
[direct: mongos] shop> sh.shardCollection("shop.visits_by_country", { country: 1 })
{
  collectionsharded: 'shop.visits_by_country',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683389, i: 40 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683389, i: 40 })
}
[direct: mongos] shop> db.adminCommand({ configureCollectionBalancing: "shop.visits_by_country", chunkSize: 1 }).ok
1
[direct: mongos] shop> visits("visits_by_country")
100000
[direct: mongos] shop> ranges("visits_by_country")
shard1 {"country":{"$minKey":1}} {"country":{"$maxKey":1}} jumbo

[direct: mongos] shop> sh.splitFind("shop.visits_by_country", { country: "BR" })
Uncaught 
MongoServerError[CannotSplit]: Unable to find median in chunk because chunk is indivisible.
[direct: mongos] shop> exit
```

One range, from the lowest possible value to the highest, marked `jumbo`, and still on `shard1`
after a minute. Asked to split it at its median, the cluster answered that the range is
`indivisible`. **A range can only be cut between two different values of the key**, and here there
is no second value. The balancer cannot move part of the collection, and it will not move all of
it, so it stops trying and marks the range.

This is **cardinality**, the number of distinct values a key can take, and it is a ceiling on how
far the collection can ever be spread: a key with four values can never use more than four shards,
however many you add. A status field, a country, a boolean flag are all keys that look harmless at
the start and fill one shard. The next section changes this one.
