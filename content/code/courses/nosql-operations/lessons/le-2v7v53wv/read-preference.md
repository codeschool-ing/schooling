---
title: Read preference, and a read that is out of date
version: 1
---

Writes have one destination, the primary. **Reads can go anywhere, and read preference says where.**
The default sends them to the primary too, and that is the only setting under which a read is
guaranteed to see the write that was just acknowledged. Every other setting trades that guarantee
for something: a primary with less work, a copy closer to the reader, or an answer while there is
no primary at all.

| mode | where a read goes |
|---|---|
| `primary` | the primary; with no primary, the read fails |
| `primaryPreferred` | the primary, and a secondary only while there is none |
| `secondary` | a secondary; with none, the read fails |
| `secondaryPreferred` | a secondary, and the primary only while no secondary answers |
| `nearest` | whichever member answers fastest, primary or not |

## Connecting the way an application does

Until now every session went `direct:` to one container. An application connects to the **set**:
a connection string lists some members and names the set, and the driver asks them who is who,
finds the primary, and keeps watching. `mongosh` does the same when given such a string, and its
prompt drops the word `direct`. Ask where each mode sends one read, using `explain()`, which
reports the server that ran it:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0"
rs0 [primary] shop> for (const mode of ["primary", "primaryPreferred", "secondary", "secondaryPreferred", "nearest"]) print(mode.padEnd(20), db.products.find().readPref(mode).explain().serverInfo.host)
primary              mongo3
primaryPreferred     mongo3
secondary            mongo1
secondaryPreferred   mongo1
nearest              mongo2

rs0 [primary] shop> exit
```

`primary` and `primaryPreferred` went to `mongo3`, this run's primary. `secondary` and
`secondaryPreferred` went to `mongo1`, one of the two secondaries. `nearest` picked `mongo2`: the
driver measures each member's round trip and chooses at random among those within 15 ms of the
fastest, and on one machine every member is that close.

## A stale read, made on purpose

A secondary is behind the primary by however long replication takes, usually milliseconds, and
lesson 5 said what an application has to tolerate in that window. To hold the window open long
enough to look at it, freeze both secondaries again, `mongo1` and `mongo2` this time, and change a
price with `w: 1`:

```
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec -it mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0"
rs0 [primary] shop> db.products.updateOne({ _id: "KB-101" }, { $set: { price: Decimal128("329.90") } }, { writeConcern: { w: 1 } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
rs0 [primary] shop> db.products.find({ _id: "KB-101" }, { price: 1 })
[ { _id: 'KB-101', price: Decimal128('329.90') } ]
rs0 [primary] shop> db.products.find({ _id: "KB-101" }, { price: 1 }).readPref("secondary")
[ { _id: 'KB-101', price: Decimal128('349.90') } ]
rs0 [primary] shop> db.products.find({ _id: "KB-101" }, { price: 1 }).readConcern("majority")
[ { _id: 'KB-101', price: Decimal128('349.90') } ]
rs0 [primary] shop> exit
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0" --eval 'db.products.find({ _id: "KB-101" }, { price: 1 }).readConcern("majority")'
[ { _id: 'KB-101', price: Decimal128('329.90') } ]
```

The primary answered 329.90 and the secondary 349.90, **one product with two prices at the same
moment**, and both reads succeeded. Nothing in the answer says which one is old.

## Read concern: what a read may return

The last read in that session asked for something else. **Read concern** says how settled the data
must be, independently of where the read goes. The default, `"local"`, returns whatever the member
has, including writes only it has seen. `"majority"` returns only what a majority of members have
acknowledged, and that can never be rolled back, because any future primary is bound to have it.

On the primary, with both secondaries frozen, `"local"` saw the new price and `"majority"` the old
one: the change had reached one member of three. Once the secondaries were unlocked, the same
`"majority"` read returned 329.90.

So **`"majority"` buys durability, not freshness**. It can return something older than `"local"`
does on the same member at the same instant; what it never returns is a value that is about to
disappear. A client that must read what it has just written reads from the primary, or uses a
causally consistent session, which tells the server which write it is waiting for; that second
option was not run in this lesson.
