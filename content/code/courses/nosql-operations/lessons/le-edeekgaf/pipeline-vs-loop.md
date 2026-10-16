---
title: The same total, by a loop and by the pipeline
version: 1
---

The loop in the application is not wrong because it is a loop. It is wrong because of **where the
data has to go** for it to run: every document the loop reads crosses from the server to the
program, and the server only ever had to send one number.

## Measuring both

`measure` runs a piece of work and reports how long it took and how many bytes the server sent
meanwhile, read from `serverStatus` before and after. The first piece of work is the loop: fetch
every order that is not cancelled and add the totals in JavaScript. The second is a two-stage
pipeline. The third, a plain count, measures what `measure` itself costs:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> function measure(work) {
|   const before = db.serverStatus().network.bytesOut;
|   const start = Date.now();
|   const result = work();
|   return { result: result, ms: Date.now() - start, bytesOut: db.serverStatus().network.bytesOut - before };
| }
[Function: measure]
shop> measure(() => {
|   let revenue = 0, orders = 0;
|   db.orders.find({ status: { $ne: "cancelled" } }).forEach((o) => { revenue += parseFloat(o.total.toString()); orders++; });
|   return { orders: orders, revenue: revenue };
| })
{
  result: { orders: 98958, revenue: 206042969.6000362 },
  ms: 6989,
  bytesOut: 24564648
}
shop> measure(() => db.orders.aggregate([
|   { $match: { status: { $ne: "cancelled" } } },
|   { $group: { _id: null, orders: { $sum: 1 }, revenue: { $sum: "$total" } } }
| ]).toArray())
{
  result: [ { _id: null, orders: 98958, revenue: Decimal128('206042969.60') } ],
  ms: 78,
  bytesOut: 111198
}
shop> measure(() => db.orders.countDocuments())
{ result: 100000, ms: 29, bytesOut: 111172 }
shop> exit
```

| | documents sent | bytes sent | time on the lab | revenue |
|---|---|---|---|---|
| loop in mongosh | 98,958 | 24,564,648 | 6,989 ms | `206042969.6000362` |
| pipeline | 1 | 111,198 | 78 ms | `Decimal128('206042969.60')` |
| a count, for scale | 1 | 111,172 | 29 ms | |

**The byte counts include the two `serverStatus` replies** that `measure` asks for, about 111 KB,
which the count shows on its own. Take that away and the pipeline sent almost nothing, while the
loop sent 24.5 MB: the whole collection, minus the cancelled orders, over a connection that here
never left the container. Between two machines, that is 24.5 MB of network for every run of a
report.

**The times are this run's, on the lab, and they vary**: run it twice and both numbers move. The
size of the gap does not, about ninety times here, because the loop's cost is dominated by moving
and decoding every document, and the pipeline's by reading them once where they already are.

## And the loop got the money wrong

The pipeline's total is `206042969.60`. The loop's is `206042969.6000362`. The loop had to turn
each `Decimal128` into something JavaScript can add, and `parseFloat` turned it into a double, so
every addition carried the binary rounding error lesson 6 measured on three keyboards. After
98,958 additions the total was off by 0.0000362. It is a small number, and it is a
wrong one, in a report whose job is to agree with the bank to the cent.

A loop can be written correctly, with a decimal library or with integer cents. The pipeline did
not have to be: **the arithmetic ran where the type is exact**, and the program received the
answer in the type it was stored in.

## When the loop is right

The pipeline wins where the result is small and the input is large: totals, counts, top tens,
anything that ends in a `$group` or a `$limit`. It does not win when the program needs every
document anyway, to write each one to a file or to call another service per order; then the
documents cross the connection either way, and a pipeline only adds a stage. And logic the
pipeline's operators cannot express, or can express only unreadably, belongs in the application,
fed by a `$match` and a `$project` that send it as little as possible.
