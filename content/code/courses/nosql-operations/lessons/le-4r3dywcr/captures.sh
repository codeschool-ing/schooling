#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Nothing is staged. The network and the three containers are started by the
# block the lesson shows (document.md), read out of the lesson, and every row
# of data is written by a statement shown in a transcript. Graph and time
# series stores are described in the lesson and not installed, so nothing here
# runs them.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet "$(from document.md 'docker network create nosql')"
quiet 'ready_mongo mongo'; quiet 'ready_redis redis'; quiet 'ready_cassandra cassandra'

block mongo-insert
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
const cable = { sku: "CB-012", name: "USB-C cable", qty: 2, unit_price: Decimal128("39.90") }
const mouse = { sku: "MS-204", name: "Wireless mouse", qty: 1, unit_price: Decimal128("189.00") }
db.orders.insertOne({ _id: 1001, customer: "ana@example.com", ordered_at: ISODate("2026-09-14T13:22:00Z"), lines: [cable, mouse], total: Decimal128("268.80") })
db.orders.findOne({ _id: 1001 })
exit
S

block mongo-query
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.orders.insertOne({ _id: 1002, customer: "bruno@example.com", ordered_at: ISODate("2026-09-15T17:05:00Z"), lines: [{ sku: "MN-330", name: "27-inch monitor", qty: 1, unit_price: Decimal128("1499.00") }], total: Decimal128("1499.00") })
db.orders.find({ "lines.sku": "MS-204" }, { customer: 1, total: 1 })
db.orders.find({ total: { $gt: Decimal128("500") } }, { customer: 1, total: 1 })
exit
S

block redis-string
session 'docker exec -it redis redis-cli' <<'S'
SET order:1001 '{"customer":"ana@example.com","lines":[{"sku":"CB-012","qty":2,"unit_price":"39.90"},{"sku":"MS-204","qty":1,"unit_price":"189.00"}],"total":"268.80"}'
GET order:1001
TYPE order:1001
HGET order:1001 total
exit
S

block redis-hash
session 'docker exec -it redis redis-cli' <<'S'
DEL order:1001
HSET order:1001 customer ana@example.com ordered_at 2026-09-14T10:22:00-03:00 total 268.80
HGET order:1001 total
HGETALL order:1001
HSET order:1001 lines '[{"sku":"CB-012","qty":2},{"sku":"MS-204","qty":1}]'
TYPE order:1001
exit
S

block cassandra
session 'docker exec -it cassandra cqlsh' <<'S'
CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE shop;
CREATE TABLE order_lines_by_customer (customer text, ordered_at timestamp, sku text, order_id int, name text, qty int, unit_price decimal, PRIMARY KEY ((customer), ordered_at, sku));
INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 'CB-012', 1001, 'USB-C cable', 2, 39.90);
INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 'MS-204', 1001, 'Wireless mouse', 1, 189.00);
INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-08-02 19:40:00-0300', 'KB-101', 987, 'Mechanical keyboard', 1, 349.90);
INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 'MN-330', 1002, '27-inch monitor', 1, 1499.00);
SELECT ordered_at, sku, order_id, qty, unit_price FROM order_lines_by_customer WHERE customer = 'ana@example.com';
SELECT customer, sku, unit_price FROM order_lines_by_customer WHERE unit_price > 500;
SELECT customer, sku, unit_price FROM order_lines_by_customer WHERE unit_price > 500 ALLOW FILTERING;
exit
S
