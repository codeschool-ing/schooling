---
title: Covered queries and indexes on arrays
version: 1
---

Every plan so far ended in `FETCH`: the index said where the documents were, and the server
opened each one. Two kinds of index change that picture. One answers without opening any document.
The other indexes the elements of an array, which a table's index has no equivalent for.

## A query the index answers on its own

Ana's order history needs a date and a total per order and nothing else. If every field the query
filters on, sorts by and returns is in one index, the documents are never read:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ customer: 1, ordered_at: -1, total: 1 })
customer_1_ordered_at_-1_total_1
shop> summary(db.orders.find({ customer: "ana@example.com" }, { _id: 0, ordered_at: 1, total: 1 }).sort({ ordered_at: -1 }))
{
  stages: 'PROJECTION_COVERED <- IXSCAN',
  returned: 82,
  keys: 82,
  docs: 0,
  ms: 4
}
shop> summary(db.orders.find({ customer: "ana@example.com" }, { ordered_at: 1, total: 1 }).sort({ ordered_at: -1 }))
{
  stages: 'PROJECTION_SIMPLE <- FETCH <- IXSCAN',
  returned: 82,
  keys: 82,
  docs: 82,
  ms: 1
}
shop> exit
```

**`docs: 0`, and the plan is `PROJECTION_COVERED <- IXSCAN`.** The 82 dates and totals came out of
the index entries themselves. That matters more than the milliseconds suggest: an index is small
and mostly in memory, and documents are large and may be on disk, so a covered query on a busy
server avoids the reads that are the slow part.

The second query differs by one thing: it did not say `_id: 0`. `_id` comes back unless excluded,
as lesson 6 showed, it is not in this index, so the server had to open every document to get it,
and the plan grew a `FETCH` with `docs: 82`. **A covered query is fragile in exactly that way**: one
more field in a projection, added by somebody who did not know, turns it back into a fetch, and
nothing fails.

## An index on the inside of an array

Each order keeps its lines in the array `items`. Index `items.sku`, and the server writes one entry
for every distinct SKU in every order:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ "items.sku": 1 })
items.sku_1
shop> summary(db.orders.find({ "items.sku": "MN-330" }))
{
  stages: 'FETCH <- IXSCAN',
  returned: 42139,
  keys: 42139,
  docs: 42139,
  ms: 70
}
shop> db.orders.find({ "items.sku": "MN-330" }).explain().queryPlanner.winningPlan.inputStage.isMultiKey
true
shop> db.orders.validate().keysPerIndex
{
  _id_: 100000,
  customer_1: 100000,
  'customer_1_ordered_at_-1_total_1': 100000,
  'items.sku_1': 169164,
  'ordered_at_-1_status_1': 100000,
  status_1: 100000,
  'status_1_ordered_at_-1': 100000,
  'status_1_ordered_at_-1_total_1': 100000,
  'status_1_total_1_ordered_at_-1': 100000
}
shop> db.labels.insertOne({ tags: ["gift", "fragile"], sizes: [1, 2] })
{
  acknowledged: true,
  insertedId: ObjectId('6acae9916e351c81c753ea4d')
}
shop> db.labels.createIndex({ tags: 1, sizes: 1 })
Uncaught 
MongoServerError[CannotIndexParallelArrays]: Index build failed: 777236ab-40fa-45f3-ad3b-8ae57cc2d841: Collection shop.labels ( 7aeb54c4-4d87-4648-a143-29002d58f2d6 ) :: caused by :: collection scan stopped. totalRecords: 0; durationMillis: 2ms; phase: collection scan; collectionScanPosition: (None); readSource: kNoTimestamp :: caused by :: cannot index parallel arrays [sizes] [tags]
shop> exit
```

The index serves the query in the usual way, and explain reports **`isMultiKey: true`**, which the
server set by itself the first time it indexed a document whose `items` held more than one
element. `keysPerIndex` shows what that means in size: every other index has exactly 100,000
entries, one per order, and **`items.sku_1` has 169,164**, because an order with three different
SKUs puts three entries in it. An order that lists the same SKU twice puts one.

A multikey index has two limits worth knowing before they surprise you.

- **It cannot cover a query on the array field.** An entry says that one of the order's lines has
  that SKU; it cannot say which line, or how many, so the document has to be read.
- **A compound index may have at most one array field per document.** The last command tried to
  index two arrays together, and the server refused with `cannot index parallel arrays [sizes]
  [tags]`: one entry for every pair of elements would grow as the product of the two arrays'
  lengths. The refusal also happens later, to an insert, when an index on two fields exists and a
  document arrives with arrays in both.

The query itself is a warning of another kind. The monitor is in 42,139 orders out of 100,000, so
the index found 42,139 entries and the server opened 42,139 documents. **An index on a value that
matches nearly half the collection saves little**, and the planner would do almost as well
reading everything. Indexes pay off on selective fields, the ones where a value picks out a small
slice, as `customer` did with 82 orders out of 100,000.
