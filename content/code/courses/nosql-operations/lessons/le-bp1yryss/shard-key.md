---
title: The shard key, ranged or hashed
version: 1
---

The shard key is a field, or a few fields, that every document of a sharded collection carries.
**The cluster cuts the range of its values into pieces and gives each piece to a shard**, so the
key decides two things at once: where each new document is written, and which shards a query has
to ask. A key that is good for one and bad for the other is the usual mistake, and the commonest
version of it looks perfectly sensible.

## An order number that only grows

Order numbers go up by one for each new order. As a **ranged** key, `{ orderId: 1 }`, the values
are kept in order, so neighbouring orders sit in the same range. The session below shards
`orders` on it, splits the empty collection at 5001 and moves the upper range to `shard2`, so that
each shard owns half of the number line before anything is written.

Two helpers are typed first, because the session uses each twice. `spread` asks the cluster how
many documents each shard owns, through the `$shardedDataDistribution` stage. `load` generates
orders with consecutive numbers between two values, the way a shop's order numbers arrive, and
returns the collection's count:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> sh.enableSharding("shop", "shard1")
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683230, i: 3 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683229, i: 6 })
}
[direct: mongos] shop> sh.shardCollection("shop.orders", { orderId: 1 })
{
  collectionsharded: 'shop.orders',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683231, i: 36 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683231, i: 36 })
}
[direct: mongos] shop> sh.splitAt("shop.orders", { orderId: 5001 })
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683232, i: 7 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683232, i: 7 })
}
[direct: mongos] shop> sh.moveChunk("shop.orders", { orderId: 5001 }, "shard2")
{
  millis: 192,
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683233, i: 42 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683233, i: 42 })
}
[direct: mongos] shop> function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }
[Function: spread]
[direct: mongos] shop> function load(coll, first, last) { const customers = ["ana@example.com", "bruno@example.com", "carla@example.com", "diego@example.com", "elisa@example.com"]; const docs = []; for (let id = first; id <= last; id++) docs.push({ orderId: id, customer: customers[id % 5], sku: "KB-101", qty: 1 + id % 3 }); db.getCollection(coll).insertMany(docs); return db.getCollection(coll).countDocuments() }
[Function: load]
[direct: mongos] shop> load("orders", 1, 10000)
10000
[direct: mongos] shop> spread("orders")
[
  { shard: 'shard2', owned: 5000, orphaned: 0 },
  { shard: 'shard1', owned: 5000, orphaned: 0 }
]
[direct: mongos] shop> load("orders", 10001, 20000)
20000
[direct: mongos] shop> spread("orders")
[
  { shard: 'shard1', owned: 5000, orphaned: 0 },
  { shard: 'shard2', owned: 15000, orphaned: 0 }
]
[direct: mongos] shop> exit
```

The first 10,000 orders split evenly, 5,000 a shard, because half of their numbers fell below
5001. **The next 10,000 all went to `shard2`**, which ended with 15,000 against `shard1`'s 5,000.
Every new order number is higher than any before it, so every new order falls in the top range, and
the top range is on one shard. Split it again and the newest piece is still on one shard; move it
and the hot spot moves with it. With a growing key, **all of the write load lands on one shard at a
time**, and adding shards adds machines that receive none of it. Timestamps, `ObjectId`s and any
counter behave the same way.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Two number lines of order numbers. Above, a ranged key: shard1 owns the numbers below 5001 and shard2 the numbers from 5001 up, and every new order, numbered 10,001 to 20,000, lands at the top end, on shard2. Below, a hashed key: the same new orders are hashed, and their hashes fall all over the range, on both shards.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">ranged key</text><rect x=\"40\" y=\"50\" width=\"220\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard1</text><rect x=\"260\" y=\"50\" width=\"400\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard2</text><text x=\"40\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">MinKey</text><text x=\"260\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">5001</text><text x=\"660\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">MaxKey</text><text x=\"560\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">new orders 10,001 to 20,000</text><line x1=\"600\" y1=\"52\" x2=\"600\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"608\" y1=\"52\" x2=\"608\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"616\" y1=\"52\" x2=\"616\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"624\" y1=\"52\" x2=\"624\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"632\" y1=\"52\" x2=\"632\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"640\" y1=\"52\" x2=\"640\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"648\" y1=\"52\" x2=\"648\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"560\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">all 10,000 here</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">hashed key</text><rect x=\"40\" y=\"170\" width=\"310\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"195\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shard1</text><rect x=\"350\" y=\"170\" width=\"310\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shard2</text><line x1=\"242.9\" y1=\"172\" x2=\"242.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"137.7\" y1=\"172\" x2=\"137.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"441.8\" y1=\"172\" x2=\"441.8\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"90.0\" y1=\"172\" x2=\"90.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"371.8\" y1=\"172\" x2=\"371.8\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"268.3\" y1=\"172\" x2=\"268.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"81.3\" y1=\"172\" x2=\"81.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"354.5\" y1=\"172\" x2=\"354.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"68.8\" y1=\"172\" x2=\"68.8\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"309.7\" y1=\"172\" x2=\"309.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"88.5\" y1=\"172\" x2=\"88.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"101.2\" y1=\"172\" x2=\"101.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"304.1\" y1=\"172\" x2=\"304.1\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"548.7\" y1=\"172\" x2=\"548.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"121.3\" y1=\"172\" x2=\"121.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"181.7\" y1=\"172\" x2=\"181.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"427.5\" y1=\"172\" x2=\"427.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"622.2\" y1=\"172\" x2=\"622.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"396.9\" y1=\"172\" x2=\"396.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"287.2\" y1=\"172\" x2=\"287.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"639.6\" y1=\"172\" x2=\"639.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"74.3\" y1=\"172\" x2=\"74.3\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"567.9\" y1=\"172\" x2=\"567.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"222.1\" y1=\"172\" x2=\"222.1\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"133.7\" y1=\"172\" x2=\"133.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"117.6\" y1=\"172\" x2=\"117.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"233.6\" y1=\"172\" x2=\"233.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"542.2\" y1=\"172\" x2=\"542.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"155.9\" y1=\"172\" x2=\"155.9\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"399.6\" y1=\"172\" x2=\"399.6\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"434.5\" y1=\"172\" x2=\"434.5\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"272.4\" y1=\"172\" x2=\"272.4\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"379.0\" y1=\"172\" x2=\"379.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"84.2\" y1=\"172\" x2=\"84.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"82.2\" y1=\"172\" x2=\"82.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"171.2\" y1=\"172\" x2=\"171.2\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"459.7\" y1=\"172\" x2=\"459.7\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"306.0\" y1=\"172\" x2=\"306.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"237.0\" y1=\"172\" x2=\"237.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"402.0\" y1=\"172\" x2=\"402.0\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"350\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">spread over both</text></svg>", "caption": "Where the next 10,000 orders went. A growing value always lands in the top range; its hash lands anywhere."}
```

## The same orders under a hashed key

`{ orderId: "hashed" }` keeps the field but shards on a hash of its value, which scatters
neighbouring numbers across the whole range. Sharding an empty collection this way also creates
one range per shard straight away:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> function load(coll, first, last) { const customers = ["ana@example.com", "bruno@example.com", "carla@example.com", "diego@example.com", "elisa@example.com"]; const docs = []; for (let id = first; id <= last; id++) docs.push({ orderId: id, customer: customers[id % 5], sku: "KB-101", qty: 1 + id % 3 }); db.getCollection(coll).insertMany(docs); return db.getCollection(coll).countDocuments() }
[Function: load]
[direct: mongos] shop> sh.shardCollection("shop.orders_hashed", { orderId: "hashed" })
{
  collectionsharded: 'shop.orders_hashed',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791683244, i: 44 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791683244, i: 43 })
}
[direct: mongos] shop> load("orders_hashed", 1, 20000)
20000
[direct: mongos] shop> db.orders_hashed.getShardDistribution()
Shard shard2 at shard2/shard2:27017
{
  data: '907KiB',
  docs: 10141,
  chunks: 1,
  'estimated data per chunk': '907KiB',
  'estimated docs per chunk': 10141
}
---
Shard shard1 at shard1/shard1:27017
{
  data: '881KiB',
  docs: 9859,
  chunks: 1,
  'estimated data per chunk': '881KiB',
  'estimated docs per chunk': 9859
}
---
Totals
{
  data: '1.74MiB',
  docs: 20000,
  chunks: 2,
  'Shard shard2': [
    '50.7 % data',
    '50.7 % docs in cluster',
    '91B avg obj size on shard'
  ],
  'Shard shard1': [
    '49.29 % data',
    '49.29 % docs in cluster',
    '91B avg obj size on shard'
  ]
}
[direct: mongos] shop> exit
```

9,859 on one shard and 10,141 on the other, out of the same 20,000 consecutive numbers. The writes
are spread, from the first order.

## What each key costs a query

Now ask both collections the same questions, and look only at the plan's top stage, which says how
many shards `mongos` involved. `SINGLE_SHARD` means one; `SHARD_MERGE` means it asked every shard
and merged what came back:

```
ana@vm:~$ docker exec -it mongos mongosh --quiet shop
[direct: mongos] shop> db.orders.find({ orderId: 12345 }).explain().queryPlanner.winningPlan.stage
SINGLE_SHARD
[direct: mongos] shop> db.orders.find({ customer: "ana@example.com" }).explain().queryPlanner.winningPlan.stage
SHARD_MERGE
[direct: mongos] shop> db.orders.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
SINGLE_SHARD
[direct: mongos] shop> db.orders_hashed.find({ orderId: 12345 }).explain().queryPlanner.winningPlan.stage
SINGLE_SHARD
[direct: mongos] shop> db.orders_hashed.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
SHARD_MERGE
[direct: mongos] shop> exit
```

| query | ranged `orderId` | hashed `orderId` |
|---|---|---|
| one order, `orderId: 12345` | one shard | one shard |
| a range, `orderId` from 100 to 199 | one shard | **every shard** |
| by customer, a field not in the key | **every shard** | every shard |

An exact value of the key goes to one shard under either kind. **A range of the key is where they
part**: under a range key the values are neighbours and live together, and under a hash they were
deliberately scattered, so the range has to be gathered from everywhere. And a query that does not
name the key at all asks every shard whatever the key is, which is the argument for choosing a key
that the frequent queries name, lesson 3's access pattern again.

So the trade is written into the key. **Ranged keys serve range queries and concentrate growing
writes; hashed keys spread writes and scatter ranges.** A compound key, such as a customer followed
by a date, is how a real collection often gets both: writes spread over many customers, and one
customer's history read from one shard.
