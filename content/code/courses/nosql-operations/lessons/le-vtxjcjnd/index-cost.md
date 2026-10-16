---
title: What an index costs, and three that change behaviour
version: 1
---

After two sections of indexes that made queries faster, the wrong idea is within reach: **add an
index for every query and the database gets faster**. Reads do. Every write gets slower, because
each insert and each update of an indexed field changes every index, and every index takes memory
the documents would otherwise have used. This section measures both, and then meets three indexes
whose purpose is a rule rather than speed.

## Size, and which indexes anybody uses

The collection has collected nine indexes by now, two of them redundant. `stats` reports sizes in
the scale you ask for, here megabytes:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.stats({ scale: 1024 * 1024 }).size
22.922405242919922
shop> db.orders.stats({ scale: 1024 * 1024 }).indexSizes
{
  _id_: 1.04296875,
  customer_1: 0.5625,
  status_1: 0.48828125,
  'status_1_ordered_at_-1': 1.09765625,
  'ordered_at_-1_status_1': 2.15234375,
  'status_1_total_1_ordered_at_-1': 1.703125,
  'status_1_ordered_at_-1_total_1': 2.29296875,
  'customer_1_ordered_at_-1_total_1': 2.3984375,
  'items.sku_1': 0.8125
}
shop> db.orders.find({ customer: "ana@example.com" }).toArray().length
82
shop> db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20).toArray().length
20
shop> db.orders.aggregate([{ $indexStats: {} }, { $project: { _id: 0, name: 1, ops: "$accesses.ops" } }, { $sort: { name: 1 } }])
[
  { name: '_id_', ops: Long('0') },
  { name: 'customer_1', ops: Long('1') },
  { name: 'customer_1_ordered_at_-1_total_1', ops: Long('0') },
  { name: 'items.sku_1', ops: Long('0') },
  { name: 'ordered_at_-1_status_1', ops: Long('0') },
  { name: 'status_1', ops: Long('0') },
  { name: 'status_1_ordered_at_-1', ops: Long('2') },
  { name: 'status_1_ordered_at_-1_total_1', ops: Long('0') },
  { name: 'status_1_total_1_ordered_at_-1', ops: Long('0') }
]
shop> exit
```

The documents take 22.9 MB. **The nine indexes take about 12.6 MB between them**, more than half
of that again, and each one wants to be in memory when it is used. The two biggest are the
three-field compound indexes, at 2.3 and 2.4 MB.

`$indexStats` counts, per index, the operations that used it since the server started. The two
queries run just above went through `customer_1` and `status_1_ordered_at_-1`, and the counters
show it; the `explain` calls of the earlier sections are not counted. On a real server, after a
week of real traffic, **an index whose count is still zero is a candidate to drop**, and
`status_1` is the clearest one here: `status_1_ordered_at_-1` starts with the same field and
answers every query `status_1` could.

## The write cost, measured

Insert the same 100,000 documents into an empty collection twice: once with only `_id`, once with
the same eight extra indexes `orders` has:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> const docs = db.orders.find().toArray()

shop> function timedInsert() {
|   db.copy.deleteMany({});
|   const t = Date.now();
|   db.copy.insertMany(docs);
|   return Date.now() - t;
| }
[Function: timedInsert]
shop> db.copy.drop()
true
shop> timedInsert()
1294
shop> db.orders.getIndexes().filter((i) => i.name !== "_id_").forEach((i) => db.copy.createIndex(i.key))

shop> db.copy.getIndexes().length
9
shop> timedInsert()
3080
shop> db.copy.drop()
true
shop> exit
```

**1,294 milliseconds with one index, 3,080 with nine.** That is the insert, end to end, from
mongosh, and the numbers are this run's; yours will differ, as will the lab's on the next run.
What holds from run to run is the direction and the rough size: more than twice as long, for the
same documents, because each document became nine index entries instead of one. A shop that
inserts a few orders a second will not notice. A collection that takes thousands of writes a
second, such as events or sessions, notices every index it carries.

## Unique: an index that refuses

An index declared `unique` makes a second document with the same key an error, the same `E11000`
lesson 6 met on `_id`:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.customers.insertMany([{ _id: 1, email: "ana@example.com" }, { _id: 2, email: "bruno@example.com" }])
{ acknowledged: true, insertedIds: { '0': 1, '1': 2 } }
shop> db.customers.createIndex({ email: 1 }, { unique: true })
email_1
shop> db.customers.insertOne({ _id: 3, email: "ana@example.com" })
Uncaught 
MongoServerError: E11000 duplicate key error collection: shop.customers index: email_1 dup key: { email: "ana@example.com" }
shop> db.orders.createIndex({ customer: 1, status: 1 }, { unique: true })
Uncaught 
MongoServerError[DuplicateKey]: Index build failed: 247e692a-0353-43f0-b4a6-0d6b34b167ff: Collection shop.orders ( 1eb122b4-9908-49ba-9950-3c5769671f09 ) :: caused by :: E11000 duplicate key error collection: shop.orders index: customer_1_status_1 dup key: { customer: "ana@example.com", status: "cancelled" }
shop> exit
```

The duplicate e-mail was refused. **The last command is the case people meet first**: asking for a
unique index on a collection that already breaks it. The index build failed and named the first
duplicate it hit: Ana has more than one cancelled order. Nothing was created; the existing duplicates have
to be resolved before the rule can exist. A unique index is also the only way MongoDB has to make
"one per customer" true under concurrency, because two inserts checked by the application at the
same moment both see no duplicate.

## Partial: an index over some of the documents

The warehouse only ever asks about pending orders. An index restricted to them by
`partialFilterExpression` holds 4,044 entries instead of 100,000:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ ordered_at: -1 }, { name: "pending_by_date", partialFilterExpression: { status: "pending" } })
pending_by_date
shop> db.orders.stats({ scale: 1024 }).indexSizes["pending_by_date"]
64
shop> db.orders.stats({ scale: 1024 }).indexSizes["status_1_ordered_at_-1"]
1124
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date"))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 20,
  docs: 20,
  ms: 2
}
shop> summary(db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date"))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 0,
  keys: 4044,
  docs: 4044,
  ms: 24
}
shop> db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date").toArray().length
0
shop> db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).toArray().length
20
shop> exit
```

**64 KB against 1,124 KB** for the full `{ status: 1, ordered_at: -1 }`, and the warehouse query
reads 20 keys, as before. The price is a rule: the planner uses a partial index only for a query
whose filter guarantees it is inside the partial filter. A query for `status: "pending"` qualifies;
a query for `status: "paid"` does not, and the planner leaves the index alone.

The second `summary` forced it with `hint`, and the result is the reason to take that rule
seriously. **The hinted query for paid orders returned 0**, reading 4,044 pending entries and
keeping none, while the same query without the hint returned 20. A hint that names a partial index
can return an incomplete answer without an error, so a hint in application code is a promise that
the index fits the query, made by a person, and never checked again.

## TTL: an index that deletes

A session should disappear some time after its last use. A **TTL index** on a date field, with
`expireAfterSeconds`, makes the server delete each document once that field is older than the
number given:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.sessions.insertMany([
|   { _id: "s-old", customer: "ana@example.com", last_seen: new Date(Date.now() - 10 * 60 * 1000) },
|   { _id: "s-new", customer: "bruno@example.com", last_seen: new Date() }
| ])
{ acknowledged: true, insertedIds: { '0': 's-old', '1': 's-new' } }
shop> db.sessions.createIndex({ last_seen: 1 }, { expireAfterSeconds: 300 })
last_seen_1
shop> db.sessions.find({}, { _id: 1 })
[ { _id: 's-old' }, { _id: 's-new' } ]
shop> db.sessions.find({}, { _id: 1 })
[ { _id: 's-new' } ]
shop> exit
```

`s-old` was last seen ten minutes ago against a limit of five, and seventy seconds later it was
gone; `s-new` stays until five minutes after its own date. **The deletion is not immediate.** A
background task runs once a minute and removes what has expired, so a document can outlive its
limit by up to a minute, longer on a busy server. Code that must never see an expired session still
checks the date itself; the TTL index is what keeps the collection from growing for ever.
