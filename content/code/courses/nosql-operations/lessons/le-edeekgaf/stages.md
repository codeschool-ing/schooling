---
title: Stages, and revenue per month
version: 1
---

The finance team asks for revenue per month. The first program most people write fetches every
order and adds them up in the application, which is the habit from relational work done in an ORM.
MongoDB's answer is the **aggregation pipeline**: a list of stages sent to the server, where each
stage takes a stream of documents in and passes a stream of documents on, and only the last stage's
output crosses the connection.

## The orders, again

This lesson uses the 100,000 orders of lesson 7, made by the `orders.js` that lesson shows whole.
If you kept lesson 7's container, they are already there. If not, start `mongo` with `docker start
mongo`, or make it again:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
```

and run the generator once more from the directory where you saved it. It replaces the products
and the orders, and drops the indexes lesson 7 built:

```
ana@vm:~$ docker cp orders.js mongo:/orders.js
ana@vm:~$ docker exec mongo mongosh --quiet shop /orders.js
100000 orders, 4 products
```

## Four stages

Revenue per month, leaving out cancelled orders:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.aggregate([
|   { $match: { status: { $ne: "cancelled" } } },
|   { $group: {
|       _id: { $dateToString: { format: "%Y-%m", date: "$ordered_at", timezone: "America/Sao_Paulo" } },
|       orders: { $sum: 1 },
|       revenue: { $sum: "$total" }
|   } },
|   { $sort: { _id: 1 } },
|   { $project: { _id: 0, month: "$_id", orders: 1, revenue: 1 } }
| ])
[
  { orders: 33, revenue: Decimal128('83546.90'), month: '2025-12' },
  { orders: 8450, revenue: Decimal128('17461804.30'), month: '2026-01' },
  { orders: 7618, revenue: Decimal128('15943671.60'), month: '2026-02' },
  { orders: 8479, revenue: Decimal128('17652330.60'), month: '2026-03' },
  { orders: 8178, revenue: Decimal128('17010851.70'), month: '2026-04' },
  { orders: 8403, revenue: Decimal128('17497813.80'), month: '2026-05' },
  { orders: 7928, revenue: Decimal128('16348310.80'), month: '2026-06' },
  { orders: 8539, revenue: Decimal128('17674621.80'), month: '2026-07' },
  { orders: 8441, revenue: Decimal128('17996460.50'), month: '2026-08' },
  { orders: 8189, revenue: Decimal128('16728215.60'), month: '2026-09' },
  { orders: 8445, revenue: Decimal128('17446418.70'), month: '2026-10' },
  { orders: 8087, revenue: Decimal128('17196614.60'), month: '2026-11' },
  { orders: 8168, revenue: Decimal128('17002308.70'), month: '2026-12' }
]
shop> db.orders.countDocuments({ ordered_at: { $lt: ISODate("2026-01-01T03:00:00Z") } })
33
shop> exit
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 170\" role=\"img\" aria-label=\"The revenue-per-month pipeline as a row of stages, with the number of documents passing between them: 100,000 orders go into $match, 98,958 come out and go into $group, 13 come out of $group, and the same 13 pass through $sort and $project to the client.\"><defs><marker id=\"flw8-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><text x=\"60.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">collection</text><rect x=\"155\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$match</text><text x=\"200.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not cancelled</text><rect x=\"295\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$group</text><text x=\"340.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">by month</text><rect x=\"435\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$sort</text><text x=\"480.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">by month</text><rect x=\"575\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$project</text><text x=\"620.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rename _id</text><line x1=\"105\" y1=\"65\" x2=\"153\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"129.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100,000</text><line x1=\"245\" y1=\"65\" x2=\"293\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"269.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">98,958</text><line x1=\"385\" y1=\"65\" x2=\"433\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"409.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13</text><line x1=\"525\" y1=\"65\" x2=\"573\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"549.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13</text><line x1=\"620\" y1=\"90\" x2=\"620\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"620\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">13 documents to the client</text></svg>", "caption": "The stream shrinks at $group, and every stage after it handles thirteen documents. Only the last stage's output crosses the connection."}
```

Read the pipeline top to bottom, the way the documents flow:

- **`$match`** keeps the documents that pass a filter, in the same language as `find`. 98,958 of
  the 100,000 orders are not cancelled.
- **`$group`** collapses the stream into one document per value of `_id`. Here `_id` is an
  expression, the month of `ordered_at` written as text, and each group carries two accumulators:
  `$sum: 1` counts, and `$sum: "$total"` adds the totals. The sum of `Decimal128` values is a
  `Decimal128`, exact to the cent, which is why lesson 6 stored money that way.
- **`$sort`** orders the groups by month. It sorts thirteen documents, not 100,000, because it
  comes after the group.
- **`$project`** reshapes each document for whoever reads it: `_id` renamed to `month`.

A field name inside a stage is written with a dollar, `"$total"`, when it means "the value of
that field in the document going past". Without the dollar it is a literal string, and `$sum:
"total"` adds nothing, silently.

## The month is a question about a time zone

The answer has **thirteen months, and the first is `2025-12`**, with 33 orders, although every
order was placed in 2026 by the generator's clock. The generator drew its dates in UTC. The
pipeline asked for the month in `America/Sao_Paulo`, three hours behind, so an order placed at
01:00 UTC on 1 January was placed at 22:00 on 31 December in São Paulo. The count below the
pipeline confirms it: 33 orders fall before 03:00 UTC on 1 January.

Neither answer is wrong. They are answers to two different questions, and the report must say which
one it answered. A BSON date is a moment with no zone attached, as lesson 6 showed, so **the zone
belongs in the query**, in every `$dateToString`, `$month` or `$dateTrunc` that turns a moment into
a calendar date. Leave the `timezone` out and you get UTC, which is the zone of nobody in the shop's
finance team.
