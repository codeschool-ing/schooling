---
title: Compound indexes, and the order of their fields
version: 1
---

A compound index is one sorted list on several fields at once: sorted by the first field, then,
among equal values of the first, by the second, and so on. The common belief is that it **helps
any query that mentions its fields**. It helps the queries that can use its order, and which ones
those are depends entirely on which field comes first.

## Twenty pending orders, newest first

The warehouse screen shows the twenty most recent pending orders. Three indexes in turn:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
{
  stages: 'SORT <- COLLSCAN',
  returned: 20,
  keys: 0,
  docs: 100000,
  ms: 40
}
shop> db.orders.createIndex({ status: 1 })
status_1
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
{
  stages: 'SORT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 4044,
  docs: 4044,
  ms: 7
}
shop> db.orders.createIndex({ status: 1, ordered_at: -1 })
status_1_ordered_at_-1
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 20,
  docs: 20,
  ms: 2
}
shop> exit
```

| index | plan | keys read | documents read |
|---|---|---|---|
| none | `SORT <- COLLSCAN` | 0 | 100,000 |
| `{ status: 1 }` | `SORT <- FETCH <- IXSCAN` | 4,044 | 4,044 |
| `{ status: 1, ordered_at: -1 }` | `LIMIT <- FETCH <- IXSCAN` | 20 | 20 |

With `{ status: 1 }` the index found all 4,044 pending orders, and then **a `SORT` stage** put
them in date order in memory to keep twenty. A sort stage is blocking: it cannot hand back the
first result until it has read the last input, so its cost grows with the number of pending orders
rather than with the twenty on the screen. With `{ status: 1, ordered_at: -1 }` the pending orders
are already in date order inside the index, the scan stops after twenty, and there is **no `SORT`
stage at all**.

## The same two fields, the other way round

Swap the fields and ask for the pending orders of March. `hint` makes the server use the index
named, so both orders can be compared on one query:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ ordered_at: -1, status: 1 })
ordered_at_-1_status_1
shop> const march = { status: "pending", ordered_at: { $gte: ISODate("2026-03-01"), $lt: ISODate("2026-04-01") } }

shop> summary(db.orders.find(march).hint({ ordered_at: -1, status: 1 }))
{
  stages: 'FETCH <- IXSCAN',
  returned: 339,
  keys: 8574,
  docs: 339,
  ms: 11
}
shop> summary(db.orders.find(march).hint({ status: 1, ordered_at: -1 }))
{
  stages: 'FETCH <- IXSCAN',
  returned: 339,
  keys: 339,
  docs: 339,
  ms: 2
}
shop> exit
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 345\" role=\"img\" aria-label=\"Two indexes on the same two fields, drawn as sorted lists from top to bottom. On the left, status first: the entries are grouped by status, and inside the pending group they run from the newest date to the oldest, so the pending orders of March are one short stretch, 339 entries, all of them wanted. On the right, date first: the entries are grouped by date, and March is one long stretch of 8,574 entries with every status mixed together, of which only the 339 pending ones are wanted.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ status: 1, ordered_at: -1 }</text><rect x=\"60\" y=\"34\" width=\"220\" height=\"22\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"45.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">cancelled</text><rect x=\"60\" y=\"56\" width=\"220\" height=\"120\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delivered</text><rect x=\"60\" y=\"176\" width=\"220\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"193.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">paid</text><rect x=\"60\" y=\"210\" width=\"220\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Dec … newest</text><rect x=\"60\" y=\"236\" width=\"220\" height=\"16\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"170\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">March: 339 read, 339 kept</text><text x=\"170\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Jan … oldest</text><text x=\"54\" y=\"245.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pending</text><rect x=\"60\" y=\"280\" width=\"220\" height=\"40\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shipped</text><text x=\"520\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ ordered_at: -1, status: 1 }</text><rect x=\"410\" y=\"34\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"45.916666666666664\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Dec</text><rect x=\"410\" y=\"57.83333333333333\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"69.75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Nov</text><rect x=\"410\" y=\"81.66666666666666\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"93.58333333333333\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Oct</text><rect x=\"410\" y=\"105.49999999999999\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"117.41666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Sep</text><rect x=\"410\" y=\"129.33333333333331\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"141.24999999999997\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Aug</text><rect x=\"410\" y=\"153.16666666666666\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"165.08333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jul</text><rect x=\"410\" y=\"177.0\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"188.91666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jun</text><rect x=\"410\" y=\"200.83333333333334\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"212.75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">May</text><rect x=\"410\" y=\"224.66666666666669\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"236.58333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Apr</text><rect x=\"410\" y=\"248.50000000000003\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"404\" y=\"260.4166666666667\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Mar</text><line x1=\"418\" y1=\"252.50000000000003\" x2=\"418\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"433\" y1=\"252.50000000000003\" x2=\"433\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"448\" y1=\"252.50000000000003\" x2=\"448\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"463\" y1=\"252.50000000000003\" x2=\"463\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"478\" y1=\"252.50000000000003\" x2=\"478\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"493\" y1=\"252.50000000000003\" x2=\"493\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"508\" y1=\"252.50000000000003\" x2=\"508\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"523\" y1=\"252.50000000000003\" x2=\"523\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"538\" y1=\"252.50000000000003\" x2=\"538\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"553\" y1=\"252.50000000000003\" x2=\"553\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"568\" y1=\"252.50000000000003\" x2=\"568\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"583\" y1=\"252.50000000000003\" x2=\"583\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"598\" y1=\"252.50000000000003\" x2=\"598\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"613\" y1=\"252.50000000000003\" x2=\"613\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><rect x=\"410\" y=\"272.33333333333337\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"284.25000000000006\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Feb</text><rect x=\"410\" y=\"296.1666666666667\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"308.08333333333337\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jan</text><text x=\"520\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">March: 8,574 read, 339 kept</text></svg>", "caption": "The same query on the same two fields. Status first, March's pending orders sit together; date first, they are scattered through all of March, and the scan reads every entry in between."}
```

Both returned 339 orders. **`{ ordered_at: -1, status: 1 }` read 8,574 index entries to find
them**; `{ status: 1, ordered_at: -1 }` read 339. In the first, the index is sorted by date, and
March is one contiguous stretch of it with every status mixed together: the scan walks all of
March's orders and keeps the pending ones. In the second, the pending orders are one contiguous
stretch, sorted by date inside it, and March is one contiguous piece of that.

## Equality, sort, range

The rule that falls out of these numbers has a name in MongoDB's own documentation: **put the
fields tested for equality first, then the field you sort by, then the fields tested with a
range**. Equality narrows the index to one stretch. Inside it, the sort field is already in order.
A range field after that is checked entry by entry without disturbing the order.

Here is the rule obeyed and broken on one query: pending orders of 3,000 or more, newest twenty.
There are 1,139 of them:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> const big = { status: "pending", total: { $gte: NumberDecimal("3000") } }

shop> db.orders.countDocuments(big)
1139
shop> db.orders.createIndex({ status: 1, total: 1, ordered_at: -1 })
status_1_total_1_ordered_at_-1
shop> summary(db.orders.find(big).sort({ ordered_at: -1 }).limit(20).hint({ status: 1, total: 1, ordered_at: -1 }))
{
  stages: 'FETCH <- SORT <- IXSCAN',
  returned: 20,
  keys: 1139,
  docs: 20,
  ms: 4
}
shop> db.orders.createIndex({ status: 1, ordered_at: -1, total: 1 })
status_1_ordered_at_-1_total_1
shop> summary(db.orders.find(big).sort({ ordered_at: -1 }).limit(20).hint({ status: 1, ordered_at: -1, total: 1 }))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 73,
  docs: 20,
  ms: 2
}
shop> exit
```

| index | order | plan | keys read |
|---|---|---|---|
| `{ status: 1, total: 1, ordered_at: -1 }` | equality, range, sort | `FETCH <- SORT <- IXSCAN` | 1,139 |
| `{ status: 1, ordered_at: -1, total: 1 }` | equality, sort, range | `LIMIT <- FETCH <- IXSCAN` | 73 |

With the range before the sort, the index found every one of the 1,139 big pending orders
cheaply, but they come out ordered by total, so a `SORT` stage had to read them all to pick the
newest twenty. With the sort before the range, the scan walks pending orders newest first, skips
the ones under 3,000 by looking at the key, and stops when it has twenty: **73 entries read, and
no sort**. It read some entries it did not want, which looks wasteful on paper and is the cheaper
plan, because the alternative reads all of them and then sorts.

Two details the tables hide. **The direction matters only when there are two or more sort
fields**: `{ status: 1, ordered_at: -1 }` serves `sort({ ordered_at: 1 })` too, walked backwards,
but an index on `{ a: 1, b: 1 }` cannot serve `sort({ a: 1, b: -1 })`. And **a prefix of a
compound index is an index too**: `{ status: 1, ordered_at: -1 }` answers a query on `status`
alone, which makes `{ status: 1 }` redundant once the compound one exists. The last section of this
lesson counts what keeping both costs.
