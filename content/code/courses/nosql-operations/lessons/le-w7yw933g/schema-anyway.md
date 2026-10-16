---
title: The schema that exists anyway
version: 1
---

MongoDB is often sold as **schemaless**, and the word describes the server correctly and the
system wrongly. The server accepts any document into any collection. The programs that read those
documents do not: a product page expects `price` to be a number, a report expects `ordered_at` to
be a date, and a shipping job expects every order line to carry a `sku`. **The schema did not go
away. It moved out of the database and into every piece of code that reads it**, where nobody wrote
it down and nothing checks it.

## Three writes the server accepts

A new product arrives from a spreadsheet import with its price as text. A second one is typed by
hand with a misspelt field name. A third goes to a misspelt collection:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertOne({ _id: "SD-128", name: "128 GB memory card", price: "79.90", stock: 30 })
{ acknowledged: true, insertedId: 'SD-128' }
shop> db.products.insertOne({ _id: "WC-720", name: "Webcam", prcie: NumberDecimal("259.00"), stock: 8 })
{ acknowledged: true, insertedId: 'WC-720' }
shop> db.prodcuts.insertOne({ _id: "HS-300", name: "Headset", price: NumberDecimal("299.90"), stock: 5 })
{ acknowledged: true, insertedId: 'HS-300' }
shop> db.getCollectionNames()
[ 'products', 'prodcuts', 'orders' ]
shop> exit
```

All three answered `acknowledged: true`. The memory card's price is the string `"79.90"`. The
webcam has a field called `prcie` and no `price`. The headset is in a collection called
`prodcuts`, which did not exist until that insert made it; this is the habit lesson 1 noticed, the
first write creating whatever it names, and here it is the whole defect. In a relational database
each of the three is an error at the moment of the mistake, with the line number of the statement
that made it. Here each is a document, and the error arrives later, somewhere else.

## Where they surface

Run the queries the shop's own code would run:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.find({ price: { $lt: NumberDecimal("100") } }, { name: 1, price: 1 })
[ { _id: 'CB-012', name: 'USB-C cable', price: Decimal128('39.90') } ]
shop> db.products.find({}, { name: 1, price: 1 }).sort({ price: 1 })
[
  { _id: 'WC-720', name: 'Webcam' },
  { _id: 'CB-012', name: 'USB-C cable', price: Decimal128('39.90') },
  { _id: 'LS-050', name: 'Laptop stand', price: Decimal128('149.00') },
  { _id: 'MS-204', name: 'Wireless mouse', price: Decimal128('189.00') },
  {
    _id: 'KB-101',
    name: 'Mechanical keyboard',
    price: Decimal128('349.90')
  },
  {
    _id: 'MN-330',
    name: '27-inch monitor',
    price: Decimal128('1499.00')
  },
  { _id: 'SD-128', name: '128 GB memory card', price: '79.90' }
]
shop> db.products.aggregate([{ $project: { name: 1, with_tax: { $multiply: ["$price", NumberDecimal("1.1")] } } }])
Uncaught 
MongoServerError[TypeMismatch]: PlanExecutor error during aggregation :: caused by :: $multiply only supports numeric types, not string
shop> db.products.aggregate([{ $group: { _id: { $type: "$price" }, products: { $sum: 1 } } }])
[
  { _id: 'missing', products: 1 },
  { _id: 'string', products: 1 },
  { _id: 'decimal', products: 5 }
]
shop> db.products.find({ price: { $type: "string" } }, { name: 1, price: 1 })
[ { _id: 'SD-128', name: '128 GB memory card', price: '79.90' } ]
shop> db.products.find({ price: { $exists: false } })
[
  {
    _id: 'WC-720',
    name: 'Webcam',
    prcie: Decimal128('259.00'),
    stock: 8
  }
]
shop> exit
```

**"Products under 100" left out the memory card at 79.90.** MongoDB compares values of different
types by type first, in a fixed order, and a range of numbers never contains a string. The query
did not fail. It returned a short list, and nothing on the page would look wrong.

**Sorting by price put the webcam first and the memory card last.** A missing field sorts like
`null`, before every number; a string sorts after every number. The cheapest item in the
catalogue is at the end of the list, and the one with no price at all is at the top.

**The tax calculation failed outright**, `$multiply only supports numeric types, not string`, and
that is the best outcome of the three, because it is the only one that says something. It said it
in a report, about a document written by an import, possibly months after the import ran.

`prodcuts` appears in none of these answers, because nothing reads it. The headset is in the
database and absent from the shop, and only `getCollectionNames()` shows it.

## Finding what is already there

The schema a collection actually has is something you measure, and two operators do most of it.
**`$type` in a `$group`** counts the types a field takes across the whole collection: five
decimals, one string and one missing, which is the census to run before trusting any field of a
collection you inherited. **`$type` in a filter** fetches the offenders of one type, and
**`$exists: false`** fetches the documents where the field is absent, which is how the webcam's
misspelt field shows itself. The misspelt collection has no query; the list of collection names,
read by a person, is the check.

These find damage after it is done. The next section makes the server refuse it at the door.
