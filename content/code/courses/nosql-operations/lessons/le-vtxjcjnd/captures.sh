#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Nothing is staged. The network and the `mongo` container are made by the
# commands collscan-ixscan.md shows. orders.js is the annotated example in
# collscan-ixscan.md, put back together by `example`, and summary.js is that
# section's javascript fence, taken by `from`: the files run are the files the
# page shows. The generator is deterministic, so every count below comes out
# the same on every run; the timings (`ms`) do not, and the lesson says so.
# The TTL block waits 70 seconds for the server's TTL monitor, which runs once a
# minute.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet "$(from collscan-ixscan.md 'docker network create nosql' | sed -n 1p)"
quiet "$(from collscan-ixscan.md 'docker network create nosql' | sed -n 2p)"
quiet 'ready_mongo mongo'
example collscan-ixscan.md orders.js > orders.js
from collscan-ixscan.md '// summary.js: the few numbers of explain("executionStats") this lesson reads.' > summary.js

block generate
run 'docker cp orders.js mongo:/orders.js'
run 'docker cp summary.js mongo:/summary.js'
run 'docker exec mongo mongosh --quiet shop /orders.js'

block collscan
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.orders.findOne()
db.orders.find({ customer: "ana@example.com" }).explain("executionStats").executionStats
exit
S

block ixscan
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
load("/summary.js")
summary(db.orders.find({ customer: "ana@example.com" }))
db.orders.createIndex({ customer: 1 })
summary(db.orders.find({ customer: "ana@example.com" }))
exit
S

block sort
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
load("/summary.js")
summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
db.orders.createIndex({ status: 1 })
summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
db.orders.createIndex({ status: 1, ordered_at: -1 })
summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
exit
S

block reversed
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
load("/summary.js")
db.orders.createIndex({ ordered_at: -1, status: 1 })
const march = { status: "pending", ordered_at: { $gte: ISODate("2026-03-01"), $lt: ISODate("2026-04-01") } }
summary(db.orders.find(march).hint({ ordered_at: -1, status: 1 }))
summary(db.orders.find(march).hint({ status: 1, ordered_at: -1 }))
exit
S

block esr
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
load("/summary.js")
const big = { status: "pending", total: { $gte: NumberDecimal("3000") } }
db.orders.countDocuments(big)
db.orders.createIndex({ status: 1, total: 1, ordered_at: -1 })
summary(db.orders.find(big).sort({ ordered_at: -1 }).limit(20).hint({ status: 1, total: 1, ordered_at: -1 }))
db.orders.createIndex({ status: 1, ordered_at: -1, total: 1 })
summary(db.orders.find(big).sort({ ordered_at: -1 }).limit(20).hint({ status: 1, ordered_at: -1, total: 1 }))
exit
S

block covered
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
load("/summary.js")
db.orders.createIndex({ customer: 1, ordered_at: -1, total: 1 })
summary(db.orders.find({ customer: "ana@example.com" }, { _id: 0, ordered_at: 1, total: 1 }).sort({ ordered_at: -1 }))
summary(db.orders.find({ customer: "ana@example.com" }, { ordered_at: 1, total: 1 }).sort({ ordered_at: -1 }))
exit
S

block multikey
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
load("/summary.js")
db.orders.createIndex({ "items.sku": 1 })
summary(db.orders.find({ "items.sku": "MN-330" }))
db.orders.find({ "items.sku": "MN-330" }).explain().queryPlanner.winningPlan.inputStage.isMultiKey
db.orders.validate().keysPerIndex
db.labels.insertOne({ tags: ["gift", "fragile"], sizes: [1, 2] })
db.labels.createIndex({ tags: 1, sizes: 1 })
exit
S

block sizes
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.orders.stats({ scale: 1024 * 1024 }).size
db.orders.stats({ scale: 1024 * 1024 }).indexSizes
db.orders.find({ customer: "ana@example.com" }).toArray().length
db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20).toArray().length
db.orders.aggregate([{ $indexStats: {} }, { $project: { _id: 0, name: 1, ops: "$accesses.ops" } }, { $sort: { name: 1 } }])
exit
S

block writes
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
const docs = db.orders.find().toArray()
function timedInsert() {
  db.copy.deleteMany({});
  const t = Date.now();
  db.copy.insertMany(docs);
  return Date.now() - t;
}
db.copy.drop()
timedInsert()
db.orders.getIndexes().filter((i) => i.name !== "_id_").forEach((i) => db.copy.createIndex(i.key))
db.copy.getIndexes().length
timedInsert()
db.copy.drop()
exit
S

block unique
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.customers.insertMany([{ _id: 1, email: "ana@example.com" }, { _id: 2, email: "bruno@example.com" }])
db.customers.createIndex({ email: 1 }, { unique: true })
db.customers.insertOne({ _id: 3, email: "ana@example.com" })
db.orders.createIndex({ customer: 1, status: 1 }, { unique: true })
exit
S

block partial
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
load("/summary.js")
db.orders.createIndex({ ordered_at: -1 }, { name: "pending_by_date", partialFilterExpression: { status: "pending" } })
db.orders.stats({ scale: 1024 }).indexSizes["pending_by_date"]
db.orders.stats({ scale: 1024 }).indexSizes["status_1_ordered_at_-1"]
summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date"))
summary(db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date"))
db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).hint("pending_by_date").toArray().length
db.orders.find({ status: "paid" }).sort({ ordered_at: -1 }).limit(20).toArray().length
exit
S

block ttl
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.sessions.insertMany([
  { _id: "s-old", customer: "ana@example.com", last_seen: new Date(Date.now() - 10 * 60 * 1000) },
  { _id: "s-new", customer: "bruno@example.com", last_seen: new Date() }
])
db.sessions.createIndex({ last_seen: 1 }, { expireAfterSeconds: 300 })
db.sessions.find({}, { _id: 1 })
#sleep 70
db.sessions.find({}, { _id: 1 })
exit
S
