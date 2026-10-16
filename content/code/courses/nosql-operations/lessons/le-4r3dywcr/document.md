---
title: A document store, MongoDB
version: 1
---

This lesson uses the three containers lesson 1 built, on the `nosql` network. If they are stopped,
`docker start mongo redis cassandra` brings them back. If you removed them, these four lines make
them again. When only the containers are gone, the first line fails because the network already
exists, and the other three carry on:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name redis --network nosql redis:7.4
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

Cassandra needs about a minute before `cqlsh` connects; the `until` loop from lesson 1 waits for it.

## The order as one document

A document store keeps **one self-contained record per write**, in a format the server can read: a
document is a set of named fields, and a field can hold a list or another document. MongoDB stores
them in collections, inside a database. Neither has to exist first.

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> const cable = { sku: "CB-012", name: "USB-C cable", qty: 2, unit_price: Decimal128("39.90") }

shop> const mouse = { sku: "MS-204", name: "Wireless mouse", qty: 1, unit_price: Decimal128("189.00") }

shop> db.orders.insertOne({ _id: 1001, customer: "ana@example.com", ordered_at: ISODate("2026-09-14T13:22:00Z"), lines: [cable, mouse], total: Decimal128("268.80") })
{ acknowledged: true, insertedId: 1001 }
shop> db.orders.findOne({ _id: 1001 })
{
  _id: 1001,
  customer: 'ana@example.com',
  ordered_at: ISODate('2026-09-14T13:22:00.000Z'),
  lines: [
    {
      sku: 'CB-012',
      name: 'USB-C cable',
      qty: 2,
      unit_price: Decimal128('39.90')
    },
    {
      sku: 'MS-204',
      name: 'Wireless mouse',
      qty: 1,
      unit_price: Decimal128('189.00')
    }
  ],
  total: Decimal128('268.80')
}
shop> exit
```

The database `shop` was named on the command line and created by the first write, and so was the
collection `orders`. The two `const` lines are plain JavaScript in `mongosh`, building the two order
lines before the insert uses them. Three details are deliberate:

- **Money is `Decimal128`.** A JavaScript number is a binary floating-point value, and 39.90 has no
  exact binary form. `Decimal128` stores decimal digits, so `268.80` is stored as typed.
- **The date is stored in UTC.** 10:22 in São Paulo, three hours behind, is `13:22:00Z`, and a
  client converts it back for display.
- **`_id` is chosen by the application** here, as the order number. Leave it out and MongoDB
  generates an `ObjectId`, as lesson 1's first insert showed.

`findOne` handed back **the whole order in one read**: the customer, the date, both lines and the
total, with no join. That is the bargain this family makes. The unit the application uses, an
order on a screen or in an e-mail, is the unit the server stores, so the common read is one lookup.

## The server can see inside

The order is not a sealed parcel. MongoDB reads the fields of every document, nested ones included,
so a question about any of them is a query. Add Bruno's order for the monitor and ask two:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.insertOne({ _id: 1002, customer: "bruno@example.com", ordered_at: ISODate("2026-09-15T17:05:00Z"), lines: [{ sku: "MN-330", name: "27-inch monitor", qty: 1, unit_price: Decimal128("1499.00") }], total: Decimal128("1499.00") })
{ acknowledged: true, insertedId: 1002 }
shop> db.orders.find({ "lines.sku": "MS-204" }, { customer: 1, total: 1 })
[
  { _id: 1001, customer: 'ana@example.com', total: Decimal128('268.80') }
]
shop> db.orders.find({ total: { $gt: Decimal128("500") } }, { customer: 1, total: 1 })
[
  {
    _id: 1002,
    customer: 'bruno@example.com',
    total: Decimal128('1499.00')
  }
]
shop> exit
```

`"lines.sku"` reaches into the list and matches order 1001, because one of its lines is the mouse.
`$gt` compares `Decimal128` values and finds the only order over 500. The second argument of
`find` is a projection: it names the fields to return, and `_id` comes along unless you exclude it.

**Seeing inside is not the same as being fast inside.** With two orders, both queries read every
document. With two million they still would, until an index exists on the field, which is lesson 7.
And some questions cross documents rather than look inside one: how many mice were sold in
September has to open every order that has one and add up its quantities, which is the aggregation
pipeline of lesson 8.

## What the shape decided

Embedding the lines made one read cheap and fixed a direction. "Show me order 1001" is one document;
"show me every order line for the mouse, across all customers" is a search through every order. The
customer's city is not in the document at all, so showing it beside the order is a second read, from
somewhere else. Whether that second read should exist is the first decision of lesson 3.

MongoDB is the document store this course operates. CouchDB and Couchbase are others, and several
cloud services answer MongoDB's protocol without running MongoDB, which lesson 21 comes back to.
