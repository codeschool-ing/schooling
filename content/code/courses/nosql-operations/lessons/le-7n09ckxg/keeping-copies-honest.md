---
title: Keeping the copies honest
version: 1
---

Every copy in the table of the extended-reference section will, one day, fail to follow its source:
a deploy that skipped the `updateMany`, a script that died halfway, a new copy somebody added and
did not write down. **Nothing will raise an error.** Each document is valid on its own, and only
comparing a copy with its source shows the drift. So the comparison is something to write and run on
a schedule, the way a backup is restored to prove it works.

## A rename, and the copies that did not follow

The shop renames the keyboard to say which layout it has. Two open baskets hold a copy of the old
name:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard", price: Decimal128("349.90") })
{ acknowledged: true, insertedId: 'KB-101' }
shop> db.products.insertOne({ _id: "CB-012", name: "USB-C cable", price: Decimal128("39.90") })
{ acknowledged: true, insertedId: 'CB-012' }
shop> db.carts.insertOne({ _id: "ana@example.com", items: [{ sku: "KB-101", name: "Mechanical keyboard", qty: 1 }] })
{ acknowledged: true, insertedId: 'ana@example.com' }
shop> db.carts.insertOne({ _id: "carla@example.com", items: [{ sku: "CB-012", name: "USB-C cable", qty: 3 }, { sku: "KB-101", name: "Mechanical keyboard", qty: 1 }] })
{ acknowledged: true, insertedId: 'carla@example.com' }
shop> db.products.updateOne({ _id: "KB-101" }, { $set: { name: "Mechanical keyboard, ABNT2 layout" } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> const unwind = { $unwind: "$items" }

shop> const join = { $lookup: { from: "products", localField: "items.sku", foreignField: "_id", as: "product" } }

shop> const differ = { $match: { $expr: { $ne: ["$items.name", { $first: "$product.name" }] } } }

shop> db.carts.aggregate([unwind, join, differ, { $project: { sku: "$items.sku", copy: "$items.name" } }])
[
  { _id: 'ana@example.com', sku: 'KB-101', copy: 'Mechanical keyboard' },
  {
    _id: 'carla@example.com',
    sku: 'KB-101',
    copy: 'Mechanical keyboard'
  }
]
```

The check is three stages, each kept in a variable so the line that runs them stays readable:

- **`unwind`** turns each basket into one document per item;
- **`join`** looks up the product each item names, with `$lookup`, the one join MongoDB has, which
  lesson 8 takes apart;
- **`differ`** keeps the items whose copied name is not the product's current name.

It found the two copies of the keyboard, in Ana's basket and Carla's, still saying `Mechanical
keyboard`. The cable in Carla's basket was not listed: its copy matches.

## Repairing, and checking the repair

`updateMany` with `arrayFilters` changes only the array elements that match the filter: the item
whose `sku` is `KB-101`, inside every basket that has one. Then the same check runs again, ending in
`$count`:

```
shop> db.carts.updateMany({ "items.sku": "KB-101" }, { $set: { "items.$[i].name": "Mechanical keyboard, ABNT2 layout" } }, { arrayFilters: [{ "i.sku": "KB-101" }] })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 2,
  modifiedCount: 2,
  upsertedCount: 0
}
shop> db.carts.aggregate([unwind, join, differ, { $count: "drifted" }])

shop> exit
```

`matchedCount: 2` is the two baskets. The check printed **nothing at all**, and that is the answer
zero: `$count` produces a document only when something reaches it, so a clean run is an empty
result. A script that alerts on the check has to read "no document" as 0, not as a failure to run.

## Making it routine

A check that only runs when somebody remembers is a check that does not run. Three habits make the
copies trustworthy:

- **One check per copy in the table**, run on a schedule, reporting the number of drifted copies. A
  number that should be zero is easy to alert on, and lesson 20 is about alerting.
- **Repair from the source, never from another copy.** The product document is the truth; the
  basket is fixed from it.
- **Keep the check cheap.** Over millions of documents the `$lookup` above is a full pass; run it on
  a secondary or at night, or check only documents changed since the last run.

Snapshots are left out of all of this on purpose. A check that "repaired" `unit_price` in old orders
would be the worst bug in the shop.
