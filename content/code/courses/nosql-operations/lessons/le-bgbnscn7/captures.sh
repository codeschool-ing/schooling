#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Nothing is staged. The network, the Redis primary and replica, MongoDB and
# Cassandra are started by the block the lesson shows (stale-read.md), read
# out of the lesson. The replica's reconnection after `docker network connect`
# is waited for, silently, before the read that shows it converged: the lesson
# says "a few seconds later". Likewise the wait, after the disconnect, until
# the replica itself reports the link down (its repl-timeout), which the
# lesson describes as about a minute later and shows with INFO. The two "clients" of the conditional update are
# two statements typed one after the other, standing in for two application
# processes. The write timestamps given with USING TIMESTAMP are fixed values
# chosen to lie before and after the run; WRITETIME of an ordinary write is
# whatever the clock said during this run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet "$(from stale-read.md 'docker network create nosql')"
quiet 'ready_redis redis'; quiet 'ready_redis redis-replica'; quiet 'ready_mongo mongo'; quiet 'ready_cassandra cassandra'
quiet 'for i in $(seq 30); do docker exec redis-replica redis-cli INFO replication | grep -q master_link_status:up && break; sleep 1; done'

block replica-up
run 'docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_host|master_link_status)"'
run 'docker exec redis redis-cli SET stock:MN-330 1'
run 'docker exec redis-replica redis-cli GET stock:MN-330'

block partition
run 'docker network disconnect nosql redis-replica'
run 'docker exec redis redis-cli SET stock:MN-330 0'
run 'docker exec redis-replica redis-cli GET stock:MN-330'
run 'docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status)"'
run 'docker exec redis-replica redis-cli CONFIG GET replica-serve-stale-data'
quiet 'for i in $(seq 120); do docker exec redis-replica redis-cli INFO replication | grep -q master_link_status:down && break; sleep 1; done'
run 'docker exec redis-replica redis-cli CONFIG GET repl-timeout'
run 'docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status|master_link_down_since_seconds)"'
run 'docker exec redis-replica redis-cli GET stock:MN-330'

block converge
run 'docker network connect nosql redis-replica'
quiet 'for i in $(seq 60); do docker exec redis-replica redis-cli INFO replication | grep -q master_link_status:up && break; sleep 1; done'
run 'docker exec redis-replica redis-cli GET stock:MN-330'
run 'docker exec redis-replica redis-cli INFO replication | grep -E "^(role|master_link_status)"'

block idempotent
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.payments.insertOne({ _id: "pay-1001-a7f3", order: 1001, amount: Decimal128("268.80") })
db.payments.insertOne({ _id: "pay-1001-a7f3", order: 1001, amount: Decimal128("268.80") })
db.payments.countDocuments({ order: 1001 })
exit
S

block conditional
session 'docker exec -it mongo mongosh --quiet shop' <<'S'
db.products.insertOne({ _id: "MN-330", name: "27-inch monitor", stock: 1, version: 1 })
db.products.updateOne({ _id: "MN-330", version: 1 }, { $inc: { stock: -1, version: 1 } })
db.products.updateOne({ _id: "MN-330", version: 1 }, { $inc: { stock: -1, version: 1 } })
db.products.findOne({ _id: "MN-330" })
exit
S

block lww
session 'docker exec -it cassandra cqlsh' <<'S'
CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE shop;
CREATE TABLE products (sku text PRIMARY KEY, name text, price decimal);
INSERT INTO products (sku, name, price) VALUES ('MS-204', 'Wireless mouse', 189.00);
SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';
UPDATE products USING TIMESTAMP 1789000000000000 SET price = 179.00 WHERE sku = 'MS-204';
SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';
exit
S

block ahead
session 'docker exec -it cassandra cqlsh -k shop' <<'S'
UPDATE products USING TIMESTAMP 1830000000000000 SET price = 159.00 WHERE sku = 'MS-204';
UPDATE products SET price = 199.00 WHERE sku = 'MS-204';
SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';
exit
S
