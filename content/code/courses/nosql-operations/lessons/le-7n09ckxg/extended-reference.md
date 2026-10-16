---
title: The extended reference, in MongoDB
version: 1
---

This lesson uses two of the three containers, MongoDB and Cassandra, and starts them with nothing in
them. If lesson 3's are still there, remove them with `docker rm -f mongo redis cassandra`; then
these three lines make the two this lesson needs, and the first fails harmlessly if the network
already exists:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

Lesson 3 left the order holding only the customer's e-mail, so showing her name took a second read.
The **extended reference** is the usual middle way: the order keeps the reference *and* a copy of the
few fields its page shows, so the common read is one document and the full customer is still one
lookup away. The lines do the same with products: the code, plus the name and the price.

## A snapshot that must not move

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertOne({ _id: "MS-204", name: "Wireless mouse", price: Decimal128("189.00") })
{ acknowledged: true, insertedId: 'MS-204' }
shop> db.customers.insertOne({ _id: "ana@example.com", name: "Ana Ribeiro", city: "Recife" })
{ acknowledged: true, insertedId: 'ana@example.com' }
shop> const line = { sku: "MS-204", name: "Wireless mouse", qty: 1, unit_price: Decimal128("189.00") }

shop> db.orders.insertOne({ _id: 1001, customer: { id: "ana@example.com", name: "Ana Ribeiro" }, lines: [line] })
{ acknowledged: true, insertedId: 1001 }
shop> db.orders.insertOne({ _id: 1013, customer: { id: "ana@example.com", name: "Ana Ribeiro" }, lines: [line] })
{ acknowledged: true, insertedId: 1013 }
shop> db.products.updateOne({ _id: "MS-204" }, { $set: { price: Decimal128("199.00") } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.orders.findOne({ _id: 1001 }, { "lines.unit_price": 1 })
{ _id: 1001, lines: [ { unit_price: Decimal128('189.00') } ] }
shop> exit
```

Both orders carry `unit_price: 189.00`, copied from the product when the line was written. Then the
price list changes, and the mouse goes up to 199.00 in `products`. Order 1001 still says 189.00, and
**that is correct**: it is what Ana paid. An invoice, a refund and a dispute all need the price of
the day, and a design that looked the price up from `products` at read time would show her a bill
she never agreed to.

Nothing had to be done to get this right, which is why it is easy to get wrong in the other
direction. A team that later "fixes the duplication" by dropping `unit_price` from the lines and
joining to `products` has replaced a fact with a different fact, and every old order's total stops
adding up.

## A copy that must follow

The name on the order is the other kind. Ana tells the shop to call her Ana Ribeiro Lima, and the
"my orders" page should say so on every order, old ones included:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.customers.updateOne({ _id: "ana@example.com" }, { $set: { name: "Ana Ribeiro Lima" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.orders.updateMany({ "customer.id": "ana@example.com" }, { $set: { "customer.name": "Ana Ribeiro Lima" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 2,
  modifiedCount: 2,
  upsertedCount: 0
}
shop> db.orders.find({}, { "customer.name": 1 })
[
  { _id: 1001, customer: { name: 'Ana Ribeiro Lima' } },
  { _id: 1013, customer: { name: 'Ana Ribeiro Lima' } }
]
shop> exit
```

The customer document changed with `updateOne`, and then **the application changed every copy** with
`updateMany`, matched by the reference it kept beside the copy, `customer.id`. `matchedCount: 2` is
the two orders she has. Nothing in MongoDB knew those copies existed; the second statement exists
because somebody wrote down that `orders.customer.name` copies `customers.name`.

**Keep the reference beside every copy.** A copy of the name with no `id` next to it cannot be
found again except by searching for the old name, and two customers may share one.

## Which is which, decided once

The same field can be either kind depending on what the copy is for. The name on an issued invoice
is a snapshot, legally; the name on the "my orders" list follows. So the decision is written per
copy, not per field, in the same list that says where the copies are:

| copy | source | kind | updated by |
|---|---|---|---|
| `orders.lines.unit_price` | `products.price` | snapshot | nothing, ever |
| `orders.lines.name` | `products.name` | snapshot | nothing: the name as sold |
| `orders.customer.name` | `customers.name` | follows | the rename, with `updateMany` on `customer.id` |
| `carts.items.name` | `products.name` | follows | the rename, in the last section |

That table is the part of a denormalised design no database keeps for you, and the last section of
this lesson checks it against the data.
