---
title: A scan and a seek, read from explain
version: 1
---

An index is easiest to understand on a collection big enough for it to matter, and the shop of
lesson 6 has three orders. This lesson needs `mongo` from lesson 1, started with `docker start mongo`
or made again with these two lines:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
```

## A hundred thousand orders, the same ones as the lesson's

The program below fills `shop` with the four products and 100,000 orders. **It replaces both
collections**, so the products of lesson 6 and their validator go; nothing in this lesson needs
them. Save it as `orders.js` in your home directory on the VM:

```schooling-example
{
  "language": "javascript",
  "file": "orders.js",
  "parts": [
    {
      "code": "// orders.js: the shop's products and 100,000 orders, the same ones on every run.\nlet seed = 2026;\nfunction random() {\n  seed = (seed * 48271) % 2147483647;\n  return seed / 2147483647;\n}\nfunction pick(list) {\n  return list[Math.floor(random() * list.length)];\n}\n\n",
      "note": "**A random number generator you can see.** `Math.random()` gives different orders on every run, so your numbers would never match the lesson's. This is the Park–Miller generator: multiply by 48271, keep the remainder, and the same seed gives the same sequence on every machine. Every product stays below 2^53, so a JavaScript double holds it exactly."
    },
    {
      "code": "const products = [\n  { _id: \"KB-101\", name: \"Mechanical keyboard\", cents: 34990 },\n  { _id: \"MS-204\", name: \"Wireless mouse\", cents: 18900 },\n  { _id: \"MN-330\", name: \"27-inch monitor\", cents: 149900 },\n  { _id: \"CB-012\", name: \"USB-C cable\", cents: 3990 },\n];\nconst money = (cents) => Decimal128.fromString((cents / 100).toFixed(2));\n\n",
      "note": "**The four products, priced in cents.** Arithmetic on whole cents is exact; `money` turns a sum of cents into the `Decimal128` lesson 6 recommended, through a string, never through a double."
    },
    {
      "code": "const customers = [\"ana\", \"bruno\", \"carla\", \"diego\", \"elisa\"];\nfor (let n = 6; n <= 1000; n++) customers.push(\"customer\" + n);\n\n",
      "note": "**A thousand customers.** The five from lesson 6 and 995 more, so that one customer is a small slice of the orders, which is what makes an index on `customer` worth having."
    },
    {
      "code": "const statuses = [];\nfor (const [status, weight] of [[\"delivered\", 70], [\"shipped\", 15], [\"paid\", 10], [\"pending\", 4], [\"cancelled\", 1]]) {\n  for (let w = 0; w < weight; w++) statuses.push(status);\n}\n\n",
      "note": "**Statuses with weights.** A list of 100 entries where `delivered` appears 70 times and `pending` 4: picking from it uniformly gives about 70% delivered and 4% pending, the skew a real shop has."
    },
    {
      "code": "db.products.drop();\ndb.products.insertMany(products.map((p) => ({ _id: p._id, name: p.name, price: money(p.cents) })));\n\n",
      "note": "**The products collection, replaced.** `drop` removes it with its indexes and any validator, so a second run starts from the same place as the first."
    },
    {
      "code": "db.orders.drop();\nconst start = Date.UTC(2026, 0, 1);\nlet batch = [];\nfor (let id = 1; id <= 100000; id++) {\n  const items = [];\n  let cents = 0;\n  const lines = 1 + Math.floor(random() * 3);\n  for (let l = 0; l < lines; l++) {\n    const p = pick(products);\n    const qty = 1 + Math.floor(random() * 3);\n    items.push({ sku: p._id, qty: qty, price: money(p.cents) });\n    cents += qty * p.cents;\n  }\n  batch.push({\n    _id: id,\n    customer: pick(customers) + \"@example.com\",\n    status: pick(statuses),\n    ordered_at: new Date(start + Math.floor(random() * 365 * 86400) * 1000),\n    items: items,\n    total: money(cents),\n  });\n  if (batch.length === 1000) {\n    db.orders.insertMany(batch);\n    batch = [];\n  }\n}\n",
      "note": "**100,000 orders, a thousand at a time.** Each has one to three lines of one to three units, a date somewhere in 2026 to the second, and a total added up in cents. `insertMany` with a thousand documents is one round trip instead of a thousand."
    },
    {
      "code": "print(db.orders.countDocuments() + \" orders, \" + db.products.countDocuments() + \" products\");\n",
      "note": "**A count to check against.** If your run prints anything else, the file differs from this one."
    }
  ]
}
```

Every number this lesson quotes depends on those orders, so they have to be the same on your
machine as on the lab. That is the reason for the hand-written generator: run it twice, anywhere,
and the same customer has the same 82 orders.

The second file is a helper. `explain("executionStats")` answers with forty lines or more, and
this lesson compares the same five numbers again and again, so `summary` picks them out. Save it
as `summary.js`:

```javascript
// summary.js: the few numbers of explain("executionStats") this lesson reads.
function summary(cursor) {
  const e = cursor.explain("executionStats").executionStats;
  const stages = [];
  for (let s = e.executionStages; s; s = s.inputStage) stages.push(s.stage);
  return {
    stages: stages.join(" <- "),
    returned: e.nReturned,
    keys: e.totalKeysExamined,
    docs: e.totalDocsExamined,
    ms: e.executionTimeMillis,
  };
}
```

`stages` lists the plan from the outside in: `LIMIT <- FETCH <- IXSCAN` means an index scan fed a
fetch, which fed a limit. `keys` is how many index entries were read, `docs` how many documents,
and `returned` how many came back. Copy both files into the container and run the generator; it
takes a few seconds:

```
ana@vm:~$ docker cp orders.js mongo:/orders.js
ana@vm:~$ docker cp summary.js mongo:/summary.js
ana@vm:~$ docker exec mongo mongosh --quiet shop /orders.js
100000 orders, 4 products
```

## Without an index: every document

Look at one order, then ask how the server finds Ana's:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.findOne()
{
  _id: 1,
  customer: 'customer405@example.com',
  status: 'delivered',
  ordered_at: ISODate('2026-04-24T16:32:41.000Z'),
  items: [ { sku: 'MS-204', qty: 2, price: Decimal128('189.00') } ],
  total: Decimal128('378.00')
}
shop> db.orders.find({ customer: "ana@example.com" }).explain("executionStats").executionStats
{
  executionSuccess: true,
  nReturned: 82,
  executionTimeMillis: 34,
  totalKeysExamined: 0,
  totalDocsExamined: 100000,
  executionStages: {
    isCached: false,
    stage: 'COLLSCAN',
    filter: { customer: { '$eq': 'ana@example.com' } },
    nReturned: 82,
    executionTimeMillisEstimate: 29,
    works: 100001,
    advanced: 82,
    needTime: 99918,
    needYield: 0,
    saveState: 1,
    restoreState: 1,
    isEOF: 1,
    direction: 'forward',
    docsExamined: 100000
  }
}
shop> exit
```

**`COLLSCAN`, `totalDocsExamined: 100000`, `nReturned: 82`.** To return 82 orders the server
read all 100,000, because nothing told it where Ana's were. `needTime: 99918` is the same story
counted another way: that many steps produced nothing. 34 milliseconds is fast, and it is fast
because the collection fits in memory and nothing else is running. The work grows with the
collection, not with the answer: a million orders is ten times the reading for the same 82.

## With one: the entries that match, and no more

`load` runs `summary.js` inside the shell, and from then on `summary` is a function you can call:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> summary(db.orders.find({ customer: "ana@example.com" }))
{ stages: 'COLLSCAN', returned: 82, keys: 0, docs: 100000, ms: 21 }
shop> db.orders.createIndex({ customer: 1 })
customer_1
shop> summary(db.orders.find({ customer: "ana@example.com" }))
{ stages: 'FETCH <- IXSCAN', returned: 82, keys: 82, docs: 82, ms: 2 }
shop> exit
```

`createIndex({ customer: 1 })` builds a sorted list of every order's `customer` with a pointer to
the document, and answers with the index's name. The same query now reads **82 index entries and
82 documents to return 82**. The plan has two stages: `IXSCAN` walked the part of the index where
the customer is `ana@example.com`, and `FETCH` opened each document it pointed at.

The ratio to watch is **examined against returned**. `docs: 100000` against `returned: 82` is a
collection scan, whatever the milliseconds say on an idle laptop; `keys: 82, docs: 82, returned:
82` is an index doing all of the work. The milliseconds are the one column that changes from run
to run, on your machine and on the lab, and they are the least reliable of the five. The counts
are the same every time, and they are what you compare.

`1` in the index means ascending. For an index on one field the direction does not matter, because
the server can walk it either way. The next section is about when it does.
