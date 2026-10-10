#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Nothing is staged. The lab starts empty, so the network and the `mongo`
# container are made by the two commands documents-and-bson.md shows, taken
# from that fence; every document is written by a statement typed at mongosh
# below. The sections build on each other in one container, as they do for the
# student: crud.md's products are what schema-anyway.md spoils and
# validation.md guards. ObjectIds and the dates taken from the clock are
# whatever this run produced.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet "$(from documents-and-bson.md 'docker network create nosql' | sed -n 1p)"
quiet "$(from documents-and-bson.md 'docker network create nosql' | sed -n 2p)"
quiet 'ready_mongo mongo'

block bson
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
ObjectId()
ObjectId()
ObjectId().getTimestamp()
new Date("2026-03-14T10:30:00-03:00")
db.aggregate([
  { $documents: [{ n: 12, x: 12.5, big: 12345678901, price: NumberDecimal("349.90"), when: new Date(), id: ObjectId() }] },
  { $project: { n: { $type: "$n" }, x: { $type: "$x" }, big: { $type: "$big" }, price: { $type: "$price" }, when: { $type: "$when" }, id: { $type: "$id" } } }
])
exit
S

block money
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
0.1 + 0.2
349.90 * 3
db.aggregate([
  { $documents: [{ double: 349.90, decimal: NumberDecimal("349.90") }] },
  { $project: { double: { $multiply: ["$double", 3] }, decimal: { $multiply: ["$decimal", 3] } } }
])
NumberDecimal(349.90 * 3)
exit
S

block insert
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.insertMany([
  { _id: "KB-101", name: "Mechanical keyboard", price: NumberDecimal("349.90"), stock: 12 },
  { _id: "MS-204", name: "Wireless mouse", price: NumberDecimal("189.00"), stock: 40 },
  { _id: "MN-330", name: "27-inch monitor", price: NumberDecimal("1499.00"), stock: 1 },
  { _id: "CB-012", name: "USB-C cable", price: NumberDecimal("39.90"), stock: 200 }
])
db.orders.insertMany([
  { _id: 1, customer: "ana@example.com", status: "paid", ordered_at: new Date("2026-03-02T10:15:00-03:00"),
    items: [{ sku: "KB-101", qty: 1, price: NumberDecimal("349.90") }, { sku: "CB-012", qty: 2, price: NumberDecimal("39.90") }],
    total: NumberDecimal("429.70") },
  { _id: 2, customer: "bruno@example.com", status: "pending", ordered_at: new Date("2026-03-02T11:40:00-03:00"),
    items: [{ sku: "MN-330", qty: 1, price: NumberDecimal("1499.00") }],
    total: NumberDecimal("1499.00") },
  { _id: 3, customer: "carla@example.com", status: "paid", ordered_at: new Date("2026-03-03T09:05:00-03:00"),
    items: [{ sku: "MS-204", qty: 1, price: NumberDecimal("189.00") }],
    total: NumberDecimal("189.00") }
])
db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard" })
exit
S

block find
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.find({ price: { $lt: NumberDecimal("200") } }, { name: 1, price: 1 })
db.orders.find({ "items.sku": "CB-012" }, { customer: 1, total: 1 })
db.orders.find({ status: "paid" }, { _id: 0, customer: 1, ordered_at: 1 }).sort({ ordered_at: -1 })
exit
S

block update
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.orders.updateOne(
  { _id: 2 },
  { $set: { status: "paid" }, $push: { history: { status: "paid", at: new Date("2026-03-02T11:52:00-03:00") } } }
)
db.products.updateOne({ _id: "MN-330" }, { $inc: { stock: -1 } })
db.products.findOne({ _id: "MN-330" })
db.orders.updateOne({ _id: 1 }, { status: "shipped" })
db.orders.updateOne({ _id: 22 }, { $set: { status: "paid" } })
db.orders.deleteOne({ _id: 3 })
exit
S

block upsert
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.updateOne(
  { _id: "LS-050" },
  { $set: { name: "Laptop stand", price: NumberDecimal("149.00") }, $inc: { stock: 5 } },
  { upsert: true }
)
db.products.updateOne(
  { _id: "LS-050" },
  { $set: { name: "Laptop stand", price: NumberDecimal("149.00") }, $inc: { stock: 5 } },
  { upsert: true }
)
db.products.findOne({ _id: "LS-050" })
exit
S

block anyway
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.insertOne({ _id: "SD-128", name: "128 GB memory card", price: "79.90", stock: 30 })
db.products.insertOne({ _id: "WC-720", name: "Webcam", prcie: NumberDecimal("259.00"), stock: 8 })
db.prodcuts.insertOne({ _id: "HS-300", name: "Headset", price: NumberDecimal("299.90"), stock: 5 })
db.getCollectionNames()
exit
S

block anyway-read
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.find({ price: { $lt: NumberDecimal("100") } }, { name: 1, price: 1 })
db.products.find({}, { name: 1, price: 1 }).sort({ price: 1 })
db.products.aggregate([{ $project: { name: 1, with_tax: { $multiply: ["$price", NumberDecimal("1.1")] } } }])
db.products.aggregate([{ $group: { _id: { $type: "$price" }, products: { $sum: 1 } } }])
db.products.find({ price: { $type: "string" } }, { name: 1, price: 1 })
db.products.find({ price: { $exists: false } })
exit
S

block validator
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.runCommand({
  collMod: "products",
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["name", "price", "stock"],
    properties: {
      name: { bsonType: "string" },
      price: { bsonType: "decimal", minimum: 0 },
      stock: { bsonType: "int", minimum: 0 }
    }
  } }
})
db.products.insertOne({ _id: "HS-300", name: "Headset", price: 299.90, stock: 5 })
exit
S

block levels
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.updateOne({ _id: "SD-128" }, { $inc: { stock: -1 } })
db.runCommand({ collMod: "products", validationLevel: "moderate" })
db.products.updateOne({ _id: "SD-128" }, { $inc: { stock: -1 } })
db.products.find({ $nor: [db.getCollectionInfos({ name: "products" })[0].options.validator] }, { name: 1 })
exit
S

block warn
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.runCommand({ collMod: "products", validationAction: "warn" })
db.products.insertOne({ _id: "HS-300", name: "Headset", price: 299.90, stock: 5 })
exit
S
run 'docker logs mongo 2>&1 | grep "would fail validation"'

block repair
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.updateOne({ _id: "SD-128" }, { $set: { price: NumberDecimal("79.90") } })
db.products.updateOne({ _id: "WC-720" }, { $rename: { prcie: "price" } })
db.products.updateOne({ _id: "HS-300" }, { $set: { price: NumberDecimal("299.90") } })
db.products.find({ $nor: [db.getCollectionInfos({ name: "products" })[0].options.validator] }).count()
db.runCommand({ collMod: "products", validationLevel: "strict", validationAction: "error" })
exit
S

block create
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.createCollection("customers", {
  validator: { $jsonSchema: {
    required: ["email"],
    properties: { email: { bsonType: "string", pattern: "^[^@\\s]+@[^@\\s]+$" } }
  } }
})
db.customers.insertOne({ _id: 1, name: "Ana Ribeiro", email: "ana.example.com" })
db.customers.insertOne({ _id: 1, name: "Ana Ribeiro", email: "ana@example.com" })
exit
S
