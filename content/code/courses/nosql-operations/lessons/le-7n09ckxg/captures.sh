#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Nothing is staged. The network and the two containers this lesson uses
# (mongo and cassandra) are started by the block the lesson shows
# (extended-reference.md), read out of the lesson, and every document and row
# is written by a statement shown in a transcript. The guarantees of a logged
# batch that a single node cannot show failing (all or nothing across nodes)
# are described in the lesson, not demonstrated.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet "$(from extended-reference.md 'docker network create nosql')"
quiet 'ready_mongo mongo'; quiet 'ready_cassandra cassandra'

block mongo-snapshot
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.insertOne({ _id: "MS-204", name: "Wireless mouse", price: Decimal128("189.00") })
db.customers.insertOne({ _id: "ana@example.com", name: "Ana Ribeiro", city: "Recife" })
const line = { sku: "MS-204", name: "Wireless mouse", qty: 1, unit_price: Decimal128("189.00") }
db.orders.insertOne({ _id: 1001, customer: { id: "ana@example.com", name: "Ana Ribeiro" }, lines: [line] })
db.orders.insertOne({ _id: 1013, customer: { id: "ana@example.com", name: "Ana Ribeiro" }, lines: [line] })
db.products.updateOne({ _id: "MS-204" }, { $set: { price: Decimal128("199.00") } })
db.orders.findOne({ _id: 1001 }, { "lines.unit_price": 1 })
exit
S

block mongo-follow
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.customers.updateOne({ _id: "ana@example.com" }, { $set: { name: "Ana Ribeiro Lima" } })
db.orders.updateMany({ "customer.id": "ana@example.com" }, { $set: { "customer.name": "Ana Ribeiro Lima" } })
db.orders.find({}, { "customer.name": 1 })
exit
S

block cassandra-batch
session 'docker exec -it cassandra cqlsh' <<'S'
CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE shop;
CREATE TABLE orders_by_id (order_id int PRIMARY KEY, customer text, ordered_at timestamp, total decimal);
CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at, order_id)) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);
BEGIN BATCH INSERT INTO orders_by_id (order_id, customer, ordered_at, total) VALUES (1001, 'ana@example.com', '2026-09-14 10:22:00-0300', 268.80); INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 1001, 268.80); APPLY BATCH;
SELECT * FROM orders_by_id WHERE order_id = 1001;
SELECT * FROM orders_by_customer WHERE customer = 'ana@example.com';
exit
S

block cassandra-conditional
session 'docker exec -it cassandra cqlsh -k shop' <<'S'
BEGIN BATCH INSERT INTO orders_by_id (order_id, customer, ordered_at, total) VALUES (1002, 'bruno@example.com', '2026-09-15 14:05:00-0300', 1499.00) IF NOT EXISTS; INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 1002, 1499.00) IF NOT EXISTS; APPLY BATCH;
exit
S

block mongo-drift
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard", price: Decimal128("349.90") })
db.products.insertOne({ _id: "CB-012", name: "USB-C cable", price: Decimal128("39.90") })
db.carts.insertOne({ _id: "ana@example.com", items: [{ sku: "KB-101", name: "Mechanical keyboard", qty: 1 }] })
db.carts.insertOne({ _id: "carla@example.com", items: [{ sku: "CB-012", name: "USB-C cable", qty: 3 }, { sku: "KB-101", name: "Mechanical keyboard", qty: 1 }] })
db.products.updateOne({ _id: "KB-101" }, { $set: { name: "Mechanical keyboard, ABNT2 layout" } })
const unwind = { $unwind: "$items" }
const join = { $lookup: { from: "products", localField: "items.sku", foreignField: "_id", as: "product" } }
const differ = { $match: { $expr: { $ne: ["$items.name", { $first: "$product.name" }] } } }
db.carts.aggregate([unwind, join, differ, { $project: { sku: "$items.sku", copy: "$items.name" } }])
db.carts.updateMany({ "items.sku": "KB-101" }, { $set: { "items.$[i].name": "Mechanical keyboard, ABNT2 layout" } }, { arrayFilters: [{ "i.sku": "KB-101" }] })
db.carts.aggregate([unwind, join, differ, { $count: "drifted" }])
exit
S
