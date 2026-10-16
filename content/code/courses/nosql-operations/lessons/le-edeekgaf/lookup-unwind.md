---
title: Unwind, lookup and the best sellers
version: 1
---

Revenue per product needs the order lines, and they are inside an array in each order. `$group`
cannot reach into an array element by element. **`$unwind` turns one document with an array into
one document per element**, and from there the lines can be grouped like anything else.

## One order, unwound

Order 2 happens to list the wireless mouse twice, which lesson 7's multikey index counted once.
`$unwind` keeps both:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.find({ _id: 2 }, { items: 1 })
[
  {
    _id: 2,
    items: [
      { sku: 'MS-204', qty: 2, price: Decimal128('189.00') },
      { sku: 'MS-204', qty: 2, price: Decimal128('189.00') }
    ]
  }
]
shop> db.orders.aggregate([{ $match: { _id: 2 } }, { $unwind: "$items" }, { $project: { items: 1 } }])
[
  {
    _id: 2,
    items: { sku: 'MS-204', qty: 2, price: Decimal128('189.00') }
  },
  {
    _id: 2,
    items: { sku: 'MS-204', qty: 2, price: Decimal128('189.00') }
  }
]
shop> db.orders.aggregate([{ $unwind: "$items" }, { $count: "lines" }])
[ { lines: 200652 } ]
shop> exit
```

The two documents after `$unwind` are copies of order 2 with `items` replaced by one line each. Over
the whole collection, 100,000 orders become **200,652 lines**. That multiplication is the cost to
keep in mind: every stage after an `$unwind` works on the bigger stream, so a `$match` that can
discard documents belongs before it.

## The best sellers

Units and revenue per SKU, with the product's name fetched from `products`:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.aggregate([
|   { $match: { status: { $ne: "cancelled" } } },
|   { $unwind: "$items" },
|   { $group: {
|       _id: "$items.sku",
|       units: { $sum: "$items.qty" },
|       revenue: { $sum: { $multiply: ["$items.price", "$items.qty"] } }
|   } },
|   { $sort: { units: -1 } },
|   { $lookup: { from: "products", localField: "_id", foreignField: "_id", as: "product" } },
|   { $project: { _id: 0, sku: "$_id", name: { $first: "$product.name" }, units: 1, revenue: 1 } }
| ])
[
  {
    units: 99678,
    revenue: Decimal128('3977152.20'),
    sku: 'CB-012',
    name: 'USB-C cable'
  },
  {
    units: 99516,
    revenue: Decimal128('34820648.40'),
    sku: 'KB-101',
    name: 'Mechanical keyboard'
  },
  {
    units: 99197,
    revenue: Decimal128('18748233.00'),
    sku: 'MS-204',
    name: 'Wireless mouse'
  },
  {
    units: 99064,
    revenue: Decimal128('148496936.00'),
    sku: 'MN-330',
    name: '27-inch monitor'
  }
]
shop> exit
```

The pipeline, stage by stage:

- `$match` drops cancelled orders, before the stream grows.
- `$unwind` makes one document per line.
- `$group` by `items.sku` adds the units and the revenue of each line, `price` times `qty`, in
  `Decimal128`. The price is the one copied into the line when the order was placed, as lesson 6
  argued, so this is what customers paid, whatever the catalogue says today.
- `$sort` puts the most units first.
- **`$lookup`** is the join. For each document it finds the `products` whose `_id` equals this
  document's `_id`, the SKU, and puts them in an array called `product`. It is an array because a
  lookup may find any number of matches; `$first` in the `$project` takes the one there is.

The four products sold almost the same number of units, between 99,064 and 99,678, because the
generator picks a product uniformly. The revenue column is where they differ: the monitor brought
in 148,496,936.00 and the cable 3,977,152.20, for about the same units.

## Where the lookup goes

The `$lookup` ran on four documents, after the group, not on 200,652 lines. **A join placed after
the reduction does the work once per result**, and a join placed before it does the work once per
line, for the same answer. A `$lookup` is not free: each document going in costs a search of the
other collection, which is fast here only because `products` is tiny and its `_id` is indexed. On a
large collection the `foreignField` needs an index, exactly as a `find` would.

Lessons 3 and 4 explained why documents embed instead of joining. `$lookup` is the exception you
take for reports, where the join happens a few times a day on reduced data; a page that runs one on
every request is usually a sign the model should have embedded what that page reads.
