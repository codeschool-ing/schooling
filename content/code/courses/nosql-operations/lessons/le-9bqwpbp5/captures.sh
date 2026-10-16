#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Nothing is staged. The network and the three containers are started by the
# block the lesson shows (embed-or-reference.md), read out of the lesson. The
# million session keys in keys-as-queries.md are written by the one-line
# generator that section shows, piped into redis-cli --pipe. The 9 MB strings
# that reach MongoDB's document limit are built inside mongosh by the line the
# transcript shows. Timings (the KEYS and SCAN microseconds) are whatever this
# run measured.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet "$(from embed-or-reference.md 'docker network create nosql')"
quiet 'ready_mongo mongo'; quiet 'ready_redis redis'; quiet 'ready_cassandra cassandra'

block mongo-reference
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.customers.insertOne({ _id: "ana@example.com", name: "Ana Ribeiro", city: "Recife" })
const lines = [{ sku: "CB-012", qty: 2, unit_price: Decimal128("39.90") }, { sku: "MS-204", qty: 1, unit_price: Decimal128("189.00") }]
db.orders.insertOne({ _id: 1001, customer: "ana@example.com", ordered_at: ISODate("2026-09-14T13:22:00Z"), lines: lines, total: Decimal128("268.80") })
const order = db.orders.findOne({ _id: 1001 })
db.customers.findOne({ _id: order.customer })
exit
S

block mongo-limit
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
const nine = "x".repeat(9 * 1024 * 1024)
db.customers.updateOne({ _id: "ana@example.com" }, { $push: { history: nine } })
bsonsize(db.customers.findOne({ _id: "ana@example.com" }))
db.customers.updateOne({ _id: "ana@example.com" }, { $push: { history: nine } })
db.customers.findOne({ _id: "ana@example.com" }, { history: 0 })
exit
S

block cassandra
session 'docker exec -it cassandra cqlsh' <<'S'
CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE shop;
CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at)) WITH CLUSTERING ORDER BY (ordered_at DESC);
INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-08-02 19:40:00-0300', 987, 349.90);
INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 1001, 268.80);
INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1013, 1499.00);
INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 1002, 1499.00);
SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com' LIMIT 2;
SELECT customer, order_id FROM orders_by_customer ORDER BY ordered_at DESC LIMIT 3;
exit
S

block cassandra-collision
session 'docker exec -it cassandra cqlsh -k shop' <<'S'
INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1014, 39.90);
SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com';
DROP TABLE orders_by_customer;
CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at, order_id)) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);
INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1013, 1499.00);
INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1014, 39.90);
SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com';
exit
S

block redis-cart
session 'docker exec -it redis redis-cli' <<'S'
HSET cart:ana@example.com CB-012 2 MS-204 1
HINCRBY cart:ana@example.com CB-012 1
HGETALL cart:ana@example.com
exit
S

block redis-million
run "seq 1 1000000 | awk '{print \"SET session:\" \$1 \" x\"}' | docker exec -i redis redis-cli --pipe"
run 'docker exec redis redis-cli DBSIZE'

block redis-keys
session 'docker exec -it redis redis-cli' <<'S'
CONFIG RESETSTAT
KEYS cart:*
SCAN 0 MATCH cart:* COUNT 1000
exit
S
run "docker exec redis redis-cli --scan --pattern 'cart:*' --count 1000"
run 'docker exec redis redis-cli INFO commandstats | grep -E "keys|scan"'
