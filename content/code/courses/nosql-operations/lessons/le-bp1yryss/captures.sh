#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# What is staged: the network `nosql`, which lesson 1 creates, and the file
# cluster.sh, which is written from the annotated example in
# building-a-cluster.md (the program its copy button hands over) and then run
# as the lesson tells the student to run it. Every collection is filled by the
# generator functions the lesson types at mongosh. The waits for the balancer
# (#sleep inside a session) are the minute or so the lesson tells the student
# to wait; what the balancer did in that time is this run's.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
example building-a-cluster.md cluster.sh > cluster.sh

SPREAD='function spread(coll) { return db.getSiblingDB("admin").aggregate([{ $shardedDataDistribution: {} }, { $match: { ns: "shop." + coll } }, { $unwind: "$shards" }, { $project: { _id: 0, shard: "$shards.shardName", owned: "$shards.numOwnedDocuments", orphaned: "$shards.numOrphanedDocs" } }]).toArray() }'
RANGES='function ranges(coll) { const uuid = db.getSiblingDB("config").collections.findOne({ _id: "shop." + coll }).uuid; db.getSiblingDB("config").chunks.find({ uuid }).sort({ min: 1 }).forEach(c => print(c.shard, EJSON.stringify(c.min), EJSON.stringify(c.max), c.jumbo ? "jumbo" : "")) }'
LOAD='function load(coll, first, last) { const customers = ["ana@example.com", "bruno@example.com", "carla@example.com", "diego@example.com", "elisa@example.com"]; const docs = []; for (let id = first; id <= last; id++) docs.push({ orderId: id, customer: customers[id % 5], sku: "KB-101", qty: 1 + id % 3 }); db.getCollection(coll).insertMany(docs); return db.getCollection(coll).countDocuments() }'
VISITS='function visits(coll) { for (let b = 0; b < 10; b++) { const docs = []; for (let i = 0; i < 10000; i++) docs.push({ country: "BR", visitId: b * 10000 + i, sku: "MS-204", page: "/products/MS-204" }); db.getCollection(coll).insertMany(docs) } return db.getCollection(coll).countDocuments() }'

block build
run 'time sh cluster.sh'

block status
session 'docker exec -it mongos mongosh --quiet' <<'S'
sh.status()
exit
S

block ranged
session 'docker exec -it mongos mongosh --quiet shop' <<S
sh.enableSharding("shop", "shard1")
sh.shardCollection("shop.orders", { orderId: 1 })
sh.splitAt("shop.orders", { orderId: 5001 })
sh.moveChunk("shop.orders", { orderId: 5001 }, "shard2")
$SPREAD
$LOAD
load("orders", 1, 10000)
spread("orders")
load("orders", 10001, 20000)
spread("orders")
exit
S

block hashed
session 'docker exec -it mongos mongosh --quiet shop' <<S
$LOAD
sh.shardCollection("shop.orders_hashed", { orderId: "hashed" })
load("orders_hashed", 1, 20000)
db.orders_hashed.getShardDistribution()
exit
S

block explain
session 'docker exec -it mongos mongosh --quiet shop' <<'S'
db.orders.find({ orderId: 12345 }).explain().queryPlanner.winningPlan.stage
db.orders.find({ customer: "ana@example.com" }).explain().queryPlanner.winningPlan.stage
db.orders.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
db.orders_hashed.find({ orderId: 12345 }).explain().queryPlanner.winningPlan.stage
db.orders_hashed.find({ orderId: { $gte: 100, $lt: 200 } }).explain().queryPlanner.winningPlan.stage
exit
S

block balancer
session 'docker exec -it mongos mongosh --quiet shop' <<S
$SPREAD
$RANGES
$VISITS
sh.shardCollection("shop.visits", { country: 1, visitId: 1 })
db.adminCommand({ configureCollectionBalancing: "shop.visits", chunkSize: 1 }).ok
visits("visits")
spread("visits")
#sleep 90
spread("visits")
ranges("visits")
exit
S

block jumbo
session 'docker exec -it mongos mongosh --quiet shop' <<S
$RANGES
$VISITS
sh.shardCollection("shop.visits_by_country", { country: 1 })
db.adminCommand({ configureCollectionBalancing: "shop.visits_by_country", chunkSize: 1 }).ok
visits("visits_by_country")
#sleep 60
ranges("visits_by_country")
sh.splitFind("shop.visits_by_country", { country: "BR" })
exit
S

block refine
session 'docker exec -it mongos mongosh --quiet shop' <<S
$SPREAD
$RANGES
db.visits_by_country.createIndex({ country: 1, visitId: 1 })
db.adminCommand({ refineCollectionShardKey: "shop.visits_by_country", key: { country: 1, visitId: 1 } }).ok
#sleep 90
ranges("visits_by_country")
spread("visits_by_country")
exit
S

block reshard
session 'docker exec -it mongos mongosh --quiet shop' <<S
$SPREAD
const started = Date.now()
db.adminCommand({ reshardCollection: "shop.orders", key: { orderId: "hashed" } }).ok
(Date.now() - started) / 1000
spread("orders")
db.orders.find({ orderId: { \$gte: 100, \$lt: 200 } }).explain().queryPlanner.winningPlan.stage
exit
S
run 'docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" cfg1 shard1 shard2 mongos'
