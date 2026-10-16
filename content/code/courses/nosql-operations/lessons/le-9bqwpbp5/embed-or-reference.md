---
title: Embed or reference, in MongoDB
version: 1
---

This lesson uses the three containers lesson 1 built, on the `nosql` network, and nothing written in
lesson 2. If yours still hold lesson 2's data, remove them with `docker rm -f mongo redis cassandra`.
These four lines make them again, and the first fails harmlessly if the network is already there:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name redis --network nosql redis:7.4
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

In a document store every piece of data related to another has two possible homes. **Embedded**, it
sits inside the parent document and comes back with it. **Referenced**, it is a document of its own,
and the parent holds its key. Row 3 of the list, "show an order", decides for the order lines, and
the customer decides the other way.

## The lines inside, the customer by reference

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.customers.insertOne({ _id: "ana@example.com", name: "Ana Ribeiro", city: "Recife" })
{ acknowledged: true, insertedId: 'ana@example.com' }
shop> const lines = [{ sku: "CB-012", qty: 2, unit_price: Decimal128("39.90") }, { sku: "MS-204", qty: 1, unit_price: Decimal128("189.00") }]

shop> db.orders.insertOne({ _id: 1001, customer: "ana@example.com", ordered_at: ISODate("2026-09-14T13:22:00Z"), lines: lines, total: Decimal128("268.80") })
{ acknowledged: true, insertedId: 1001 }
shop> const order = db.orders.findOne({ _id: 1001 })

shop> db.customers.findOne({ _id: order.customer })
{ _id: 'ana@example.com', name: 'Ana Ribeiro', city: 'Recife' }
shop> exit
```

The order carries its lines, and they came back with it in lesson 2's single read. The customer is
only `"ana@example.com"`, the `_id` of a document in `customers`, so showing the order with her name
and city took **a second read, keyed by a value the first one returned**. The `const` lines keep
the first result in a variable, which is what an application does between the two calls.

Two reads by key are cheap, and here they are the right price. The order page needs the customer's
name; the customer's address changes on its own schedule; and Ana has many orders. Embedding her in
each would make the name a copy in every order she ever placed, and lesson 4 is about what keeping
copies costs.

## Three questions that decide

**Is it read together with the parent?** Lines are never shown without their order. A product's
reviews are shown on a page of their own, ten at a time.

**Is it bounded?** An order has a handful of lines, and the number stops growing when the order is
placed. Reviews, page views and a customer's order history grow for as long as the parent exists.

**Does it belong to the parent alone?** A line has no life outside its order. A customer is shared
by every order she placed, and changes without any of them changing.

Three yeses embed. **A single no to the second question is enough to reference**, because it is the
one with a hard wall behind it.

## The wall: 16 MB per document

A document has a maximum size, and an embedded list that keeps growing reaches it. Suppose the shop
embedded each customer's history in her customer document. Two 9 MB pushes stand in for years of
orders:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> const nine = "x".repeat(9 * 1024 * 1024)

shop> db.customers.updateOne({ _id: "ana@example.com" }, { $push: { history: nine } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> bsonsize(db.customers.findOne({ _id: "ana@example.com" }))
9437275
shop> db.customers.updateOne({ _id: "ana@example.com" }, { $push: { history: nine } })
Uncaught 
MongoServerError: BSONObj size: 18874467 (0x1200063) is invalid. Size must be between 0 and 16793600(16MB) First element: _id: "ana@example.com"
shop> db.customers.findOne({ _id: "ana@example.com" }, { history: 0 })
{ _id: 'ana@example.com', name: 'Ana Ribeiro', city: 'Recife' }
shop> exit
```

The first push succeeded and left a document of 9,437,275 bytes, as `bsonsize` measured it. The
second would have made 18,874,467 bytes, and **the server refused it**: the limit is 16 MB, 16,777,216
bytes, and the 16,793,600 in the message adds the small allowance the server keeps for its own
bookkeeping. The last `findOne` shows the refusal was clean. The document is as it was before the
second push, and every further push to it will be refused the same way.

That is the failure an unbounded embed waits for, and it arrives in production for the customers
who buy most, never in a test with three orders. Long before the wall, a document that size is
also slow: every read of Ana's name would move 9 MB, which is why the last `findOne` left the
history out with `{ history: 0 }`.
