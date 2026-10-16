---
title: Writing, reading and changing documents
version: 1
---

The shop needs two collections to start with: its products and some orders. A product's `_id` is
its SKU, because that is the name every order line will use for it. An order carries its lines
inside it, each with the price **as it was when the order was placed**, which is the duplication
lesson 4 argued for: the catalogue price may change tomorrow and this order must not.

## Insert

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertMany([
|   { _id: "KB-101", name: "Mechanical keyboard", price: NumberDecimal("349.90"), stock: 12 },
|   { _id: "MS-204", name: "Wireless mouse", price: NumberDecimal("189.00"), stock: 40 },
|   { _id: "MN-330", name: "27-inch monitor", price: NumberDecimal("1499.00"), stock: 1 },
|   { _id: "CB-012", name: "USB-C cable", price: NumberDecimal("39.90"), stock: 200 }
| ])
{
  acknowledged: true,
  insertedIds: { '0': 'KB-101', '1': 'MS-204', '2': 'MN-330', '3': 'CB-012' }
}
shop> db.orders.insertMany([
|   { _id: 1, customer: "ana@example.com", status: "paid", ordered_at: new Date("2026-03-02T10:15:00-03:00"),
|     items: [{ sku: "KB-101", qty: 1, price: NumberDecimal("349.90") }, { sku: "CB-012", qty: 2, price: NumberDecimal("39.90") }],
|     total: NumberDecimal("429.70") },
|   { _id: 2, customer: "bruno@example.com", status: "pending", ordered_at: new Date("2026-03-02T11:40:00-03:00"),
|     items: [{ sku: "MN-330", qty: 1, price: NumberDecimal("1499.00") }],
|     total: NumberDecimal("1499.00") },
|   { _id: 3, customer: "carla@example.com", status: "paid", ordered_at: new Date("2026-03-03T09:05:00-03:00"),
|     items: [{ sku: "MS-204", qty: 1, price: NumberDecimal("189.00") }],
|     total: NumberDecimal("189.00") }
| ])
{ acknowledged: true, insertedIds: { '0': 1, '1': 2, '2': 3 } }
shop> db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard" })
Uncaught 
MongoServerError: E11000 duplicate key error collection: shop.products index: _id_ dup key: { _id: "KB-101" }
shop> exit
```

`insertMany` answered with the `_id` of every document, in the order they were sent. The last
line tried a second `KB-101` and was refused with `E11000 duplicate key error`. Every collection
has a unique index on `_id` that cannot be dropped, and it is the one constraint MongoDB enforces
without being asked. That error code is worth recognising: lesson 7 makes a unique index of its
own and meets it again.

Nothing in those three statements described a collection. There was no `CREATE TABLE`: the first
insert into `products` made `products`, and the first insert into `orders` made `orders`. **The
shape of a document is whatever the statement that wrote it said.**

## Find: a filter and a projection

`find` takes two documents. The first is the **filter**, which says which documents match; the
second is the **projection**, which says which fields of them come back:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.find({ price: { $lt: NumberDecimal("200") } }, { name: 1, price: 1 })
[
  { _id: 'MS-204', name: 'Wireless mouse', price: Decimal128('189.00') },
  { _id: 'CB-012', name: 'USB-C cable', price: Decimal128('39.90') }
]
shop> db.orders.find({ "items.sku": "CB-012" }, { customer: 1, total: 1 })
[
  { _id: 1, customer: 'ana@example.com', total: Decimal128('429.70') }
]
shop> db.orders.find({ status: "paid" }, { _id: 0, customer: 1, ordered_at: 1 }).sort({ ordered_at: -1 })
[
  {
    customer: 'carla@example.com',
    ordered_at: ISODate('2026-03-03T12:05:00.000Z')
  },
  {
    customer: 'ana@example.com',
    ordered_at: ISODate('2026-03-02T13:15:00.000Z')
  }
]
shop> exit
```

Four details in that output carry most of the day-to-day work:

- **Operators begin with `$`.** `{ price: { $lt: NumberDecimal("200") } }` reads "price less than
  200". Comparing a decimal with a decimal is exact; the next section shows what happens when the
  field holds something else.
- **A dotted path reaches inside arrays.** `"items.sku": "CB-012"` matched order 1 because one of
  its lines has that SKU. No loop over the array was written, and no join to an order-lines table
  exists to be written.
- **`_id` comes back unless you say `_id: 0`.** Every other field in a projection is opt-in once
  you name one.
- **`sort` takes a field and a direction**, `-1` for descending. The dates came back in UTC, as
  the previous section said they would.

## Update: operators, never a whole document

An update names the fields it changes, with an operator for each kind of change. `$set` writes a
value, `$inc` adds to a number, `$push` appends to an array:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.updateOne(
|   { _id: 2 },
|   { $set: { status: "paid" }, $push: { history: { status: "paid", at: new Date("2026-03-02T11:52:00-03:00") } } }
| )
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.updateOne({ _id: "MN-330" }, { $inc: { stock: -1 } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.findOne({ _id: "MN-330" })
{
  _id: 'MN-330',
  name: '27-inch monitor',
  price: Decimal128('1499.00'),
  stock: 0
}
shop> db.orders.updateOne({ _id: 1 }, { status: "shipped" })
Uncaught 
MongoInvalidArgumentError: Update document requires atomic operators
shop> db.orders.updateOne({ _id: 22 }, { $set: { status: "paid" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 0,
  modifiedCount: 0,
  upsertedCount: 0
}
shop> db.orders.deleteOne({ _id: 3 })
{ acknowledged: true, deletedCount: 1 }
shop> exit
```

Order 2 changed status and gained a `history` array in one statement. The monitor's stock went
from 1 to 0. **Both happened atomically within their document**: two clients running that `$inc`
at the same moment produce -1 and -2, never two copies of -1, because the server applies the
operator to whatever value is there. Reading the stock, subtracting in the application and writing
the result back is the version that loses a sale, and it is the version people write first.

The next two answers are the ones to remember.

`updateOne({ _id: 1 }, { status: "shipped" })` was refused before it left mongosh: **`Update
document requires atomic operators`**. Without that check, a document with no `$` in it would
mean "replace the whole order with `{ status: "shipped" }`" and the lines, the total and the
customer would be gone. Replacing a whole document is a different call, `replaceOne`, so that it
cannot happen by forgetting a `$set`.

`updateOne({ _id: 22 }, …)` names an order that does not exist, and the answer is not an error.
It is `acknowledged: true` with **`matchedCount: 0`**. The server did exactly what it was asked,
which was to change every order with `_id` 22, and there were none. An application that only
checks for an exception will report that order as paid. The count is the result; read it.

`deleteOne` removed order 3 and said so with `deletedCount: 1`. The same rule applies: a delete
that matched nothing answers `deletedCount: 0`, without complaint.

## Upsert: update, or insert if nothing matched

A supplier sends a laptop stand the shop has never sold. `upsert: true` turns an update that
matches nothing into an insert built from the filter and the operators:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.updateOne(
|   { _id: "LS-050" },
|   { $set: { name: "Laptop stand", price: NumberDecimal("149.00") }, $inc: { stock: 5 } },
|   { upsert: true }
| )
{
  acknowledged: true,
  insertedId: 'LS-050',
  matchedCount: 0,
  modifiedCount: 0,
  upsertedCount: 1
}
shop> db.products.updateOne(
|   { _id: "LS-050" },
|   { $set: { name: "Laptop stand", price: NumberDecimal("149.00") }, $inc: { stock: 5 } },
|   { upsert: true }
| )
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.findOne({ _id: "LS-050" })
{
  _id: 'LS-050',
  name: 'Laptop stand',
  price: Decimal128('149.00'),
  stock: 10
}
shop> exit
```

The first call matched nothing and inserted, `upsertedCount: 1`, with the filter's `_id`. The
second call found the document and applied the operators again, so **the stock is 10, not 5**.
An upsert is often described as a way to make a write safe to repeat, and with `$set` alone it
is. With `$inc` it is not: a client that retries after a timeout restocks the shelf twice. The
operator for "only when inserting" is `$setOnInsert`; a counter that must survive retries needs
the retry to carry an identity the server can recognise, which is lesson 4's problem of writing
the same data twice, again.
