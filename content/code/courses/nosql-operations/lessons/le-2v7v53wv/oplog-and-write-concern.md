---
title: The oplog, and when a write counts as written
version: 1
---

The obvious guess is that secondaries copy the primary's data files. They do not. **A secondary
copies operations**: every change the primary makes is written, in the same storage transaction,
as an entry in a collection called `oplog.rs` in the `local` database, and each secondary fetches
those entries and applies them in order. Insert a product and look at what it left behind:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard", price: Decimal128("349.90") })
{ acknowledged: true, insertedId: 'KB-101' }
rs0 [direct: primary] shop> db.getSiblingDB("local").oplog.rs.find({ ns: "shop.products" }, { op: 1, ns: 1, o: 1, ts: 1, wall: 1 }).sort({ $natural: -1 }).limit(1)
[
  {
    op: 'i',
    ns: 'shop.products',
    o: {
      _id: 'KB-101',
      name: 'Mechanical keyboard',
      price: Decimal128('349.90')
    },
    ts: Timestamp({ t: 1791618877, i: 2 }),
    wall: ISODate('2026-10-10T07:54:37.170Z')
  }
]
rs0 [direct: primary] shop> db.adminCommand({ getDefaultRWConcern: 1 }).defaultWriteConcern
{ w: 'majority', wtimeout: 0 }
rs0 [direct: primary] shop> db.adminCommand({ getDefaultRWConcern: 1 }).defaultWriteConcernSource
implicit
rs0 [direct: primary] shop> exit
```

`op: 'i'` is an insert, `ns` the database and collection, and `o` the document as written. `ts` is
the entry's position in the log: seconds since 1970 and a counter for the operations inside one
second, and every member uses it to say how far it has got. `wall` is the clock time, in UTC. The
projection in the `find` keeps five fields; the real entry carries more, about sessions, retries
and versions, which this lesson does not need.

The oplog is a **capped collection**: it has a fixed size, and the oldest entries are overwritten
as new ones arrive. A secondary that falls further behind than the oldest entry still there can no
longer catch up from the log, and has to copy the whole data set again. How many hours the log
covers is therefore a number worth knowing on every replica set you run.

## Write concern: how many members must have it

A client that writes is told "done" at some moment, and **write concern** says which moment. `w: 1`
answers as soon as the primary has the write. `w: "majority"` answers once a majority of the
members have it, two of three here. The last two lines of the session above show the default in
MongoDB 8.0: `majority`, and `implicit`, meaning nobody set it and the server chose. `wtimeout: 0`
means the client waits as long as it takes.

To see the difference, the two secondaries have to fall behind on purpose. `db.fsyncLock()` flushes
a member's data to disk and then **blocks every write on that member**, replication included.
Lesson 11 uses it for what it is for. Here it stands in for two secondaries that cannot keep up:

```
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
```

With both secondaries frozen, write once each way:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> db.products.insertOne({ _id: "MS-204", name: "Wireless mouse", price: Decimal128("189.00") }, { writeConcern: { w: 1 } })
{ acknowledged: true, insertedId: 'MS-204' }
rs0 [direct: primary] shop> db.products.insertOne({ _id: "MN-330", name: "27-inch monitor", price: Decimal128("1499.00") }, { writeConcern: { w: "majority", wtimeout: 3000 } })
Uncaught:
MongoWriteConcernError[WriteConcernFailed]: waiting for replication timed out
Additional information: {
  wtimeout: true,
  writeConcern: { w: 'majority', wtimeout: 3000, provenance: 'clientSupplied' }
}
Result: {
  n: 1,
  electionId: ObjectId('7fffffff0000000000000001'),
  opTime: { ts: Timestamp({ t: 1791618884, i: 1 }), t: 1 },
  writeConcernError: {
    code: 64,
    codeName: 'WriteConcernFailed',
    errmsg: 'waiting for replication timed out',
    errInfo: {
      wtimeout: true,
      writeConcern: { w: 'majority', wtimeout: 3000, provenance: 'clientSupplied' }
    }
  },
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791618884, i: 1 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: 0
    }
  },
  operationTime: Timestamp({ t: 1791618884, i: 1 })
}
rs0 [direct: primary] shop> db.products.countDocuments()
3
rs0 [direct: primary] shop> exit
```

The `w: 1` insert answered at once. The majority insert waited the three seconds `wtimeout` allowed
and failed with `WriteConcernFailed`. **Then `countDocuments()` counted three products, so the
monitor was written anyway.** A write-concern error does not undo anything. It says the server
could not confirm the guarantee you asked for in the time you allowed, and the write sits on the
primary with no promise that it will survive. An application that retries it blindly writes twice;
here the fixed `_id` would turn the retry into a duplicate-key error, which is the better outcome.

Unlock the two secondaries and they apply what they missed, in order, from the oplog:

```
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
```

Why wait for a majority at all, when `w: 1` is faster? Because **a write only the primary has can be
lost**. If the primary dies before a secondary has copied it, the member elected next has never
heard of it. The last section of this lesson loses an acknowledged `w: 1` write exactly that way.
