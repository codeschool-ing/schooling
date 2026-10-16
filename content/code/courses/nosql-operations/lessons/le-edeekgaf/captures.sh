#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# STAGED: orders.js, the generator lesson 7 shows whole as an annotated example
# in its collscan-ixscan.md. It is put back together from that lesson by
# fences.py, so the file run here is the file lesson 7 shows; this lesson shows
# the commands that copy and run it. The network and the `mongo` container are
# made by the commands stages.md shows.
#
# The counts and sums are the same on every run, because the generator is
# deterministic. The times (`ms`) and the byte counts read from serverStatus
# are whatever this run measured. pipeline-limits.md lowers one server
# parameter, internalQueryMaxBlockingSortMemoryUsageBytes, to 10 MB to make a
# sort of this small collection cross it, says so, and puts it back.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet "$(from stages.md 'docker network create nosql' | sed -n 1p)"
quiet "$(from stages.md 'docker network create nosql' | sed -n 2p)"
quiet 'ready_mongo mongo'
python3 "$COURSE/lab/fences.py" example "$COURSE/lessons/le-vtxjcjnd/collscan-ixscan.md" orders.js > orders.js

block generate
run 'docker cp orders.js mongo:/orders.js'
run 'docker exec mongo mongosh --quiet shop /orders.js'

block month
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.orders.aggregate([
  { $match: { status: { $ne: "cancelled" } } },
  { $group: {
      _id: { $dateToString: { format: "%Y-%m", date: "$ordered_at", timezone: "America/Sao_Paulo" } },
      orders: { $sum: 1 },
      revenue: { $sum: "$total" }
  } },
  { $sort: { _id: 1 } },
  { $project: { _id: 0, month: "$_id", orders: 1, revenue: 1 } }
])
db.orders.countDocuments({ ordered_at: { $lt: ISODate("2026-01-01T03:00:00Z") } })
exit
S

block unwind
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.orders.find({ _id: 2 }, { items: 1 })
db.orders.aggregate([{ $match: { _id: 2 } }, { $unwind: "$items" }, { $project: { items: 1 } }])
db.orders.aggregate([{ $unwind: "$items" }, { $count: "lines" }])
exit
S

block best
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.orders.aggregate([
  { $match: { status: { $ne: "cancelled" } } },
  { $unwind: "$items" },
  { $group: {
      _id: "$items.sku",
      units: { $sum: "$items.qty" },
      revenue: { $sum: { $multiply: ["$items.price", "$items.qty"] } }
  } },
  { $sort: { units: -1 } },
  { $lookup: { from: "products", localField: "_id", foreignField: "_id", as: "product" } },
  { $project: { _id: 0, sku: "$_id", name: { $first: "$product.name" }, units: 1, revenue: 1 } }
])
exit
S

block measure
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
function measure(work) {
  const before = db.serverStatus().network.bytesOut;
  const start = Date.now();
  const result = work();
  return { result: result, ms: Date.now() - start, bytesOut: db.serverStatus().network.bytesOut - before };
}
measure(() => {
  let revenue = 0, orders = 0;
  db.orders.find({ status: { $ne: "cancelled" } }).forEach((o) => { revenue += parseFloat(o.total.toString()); orders++; });
  return { orders: orders, revenue: revenue };
})
measure(() => db.orders.aggregate([
  { $match: { status: { $ne: "cancelled" } } },
  { $group: { _id: null, orders: { $sum: 1 }, revenue: { $sum: "$total" } } }
]).toArray())
measure(() => db.orders.countDocuments())
exit
S

block pushdown
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
function stagesOf(explained) {
  const stages = [];
  JSON.stringify(explained, (key, value) => { if (key === "stage") stages.push(value); return value; });
  return stages;
}
db.orders.createIndex({ status: 1, ordered_at: -1 })
stagesOf(db.orders.explain().aggregate([{ $match: { status: "pending" } }, { $group: { _id: "$customer", orders: { $sum: 1 } } }]))
stagesOf(db.orders.explain().aggregate([{ $group: { _id: "$status", orders: { $sum: 1 } } }, { $match: { _id: "pending" } }]))
stagesOf(db.orders.explain().aggregate([{ $group: { _id: "$customer", statuses: { $push: "$status" } } }, { $match: { statuses: "pending" } }]))
exit
S

block memory
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
function sortStage(explained) {
  let sort = null;
  JSON.stringify(explained, (key, value) => { if (value && value.stage === "SORT" && "usedDisk" in value) sort = value; return value; });
  return { memLimit: sort.memLimit, totalDataSizeSorted: sort.totalDataSizeSorted, usedDisk: sort.usedDisk, spills: sort.spills };
}
const byTotal = [{ $sort: { total: -1 } }, { $skip: 99999 }]
sortStage(db.orders.explain("executionStats").aggregate(byTotal))
db.adminCommand({ setParameter: 1, internalQueryMaxBlockingSortMemoryUsageBytes: 10485760 })
db.orders.aggregate(byTotal, { allowDiskUse: false })
sortStage(db.orders.explain("executionStats").aggregate(byTotal))
db.adminCommand({ setParameter: 1, internalQueryMaxBlockingSortMemoryUsageBytes: 104857600 })
exit
S
