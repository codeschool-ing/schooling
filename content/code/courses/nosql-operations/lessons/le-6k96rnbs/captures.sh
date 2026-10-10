#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# What is staged: the network `nosql` (lesson 1), the three nodes, started by
# the loop lesson 16 shows and taken out of its fence, and the keyspace `shop`
# with one copy, as lesson 16 left it. None of that is quoted here; lesson 16
# shows it. Everything from the ALTER KEYSPACE on was typed. A node is stopped
# with `docker stop`, which is what the lesson tells the student to do.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
quiet "$(from ../le-49a23d7k/ring-and-partitions.md 'for n in 1 2 3; do')"
quiet 'ready_cassandra c1 3'
quiet "docker exec c1 cqlsh -e \"CREATE KEYSPACE shop WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 1};\""

block alter
session 'docker exec -it c1 cqlsh' <<'S'
ALTER KEYSPACE shop WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 3};
exit
S
run 'docker exec c1 nodetool status shop'

block stock
session 'docker exec -it c1 cqlsh' <<'S'
CREATE TABLE shop.stock (sku text PRIMARY KEY, name text, units int);
CONSISTENCY
CONSISTENCY ALL
INSERT INTO shop.stock (sku, name, units) VALUES ('MN-330', '27-inch monitor', 1);
SELECT * FROM shop.stock WHERE sku = 'MN-330';
exit
S
run 'docker exec c1 nodetool getendpoints shop stock MN-330'

block one-down
run 'docker stop c3'
run 'docker exec c1 nodetool status shop | grep -E "^(UN|DN)"'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY ONE
SELECT units FROM shop.stock WHERE sku = 'MN-330';
CONSISTENCY QUORUM
SELECT units FROM shop.stock WHERE sku = 'MN-330';
UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330';
CONSISTENCY ALL
SELECT units FROM shop.stock WHERE sku = 'MN-330';
UPDATE shop.stock SET units = 1 WHERE sku = 'MN-330';
exit
S

block two-down
run 'docker stop c2'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY QUORUM
SELECT units FROM shop.stock WHERE sku = 'MN-330';
CONSISTENCY ONE
SELECT units FROM shop.stock WHERE sku = 'MN-330';
UPDATE shop.stock SET units = 5 WHERE sku = 'MN-330' IF units = 0;
exit
S

block back
run "$(from levels.md 'docker start c2 c3')"
quiet 'ready_cassandra c2 3'; quiet 'ready_cassandra c3 3'
run 'docker exec c1 nodetool status shop | grep -E "^(UN|DN)"'

block lwt
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY QUORUM
UPDATE shop.stock SET units = 1 WHERE sku = 'MN-330';
UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330' IF units = 1;
UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330' IF units = 1;
INSERT INTO shop.stock (sku, name, units) VALUES ('KB-101', 'Mechanical keyboard', 5) IF NOT EXISTS;
INSERT INTO shop.stock (sku, name, units) VALUES ('KB-101', 'Mechanical keyboard', 9) IF NOT EXISTS;
SERIAL CONSISTENCY
exit
S

block lwt-trace
run "docker exec c1 cqlsh -e \"CONSISTENCY QUORUM; TRACING ON; UPDATE shop.stock SET units = 4 WHERE sku = 'KB-101';\" | grep -oE 'Sending [A-Z0-9_]+ message to /[0-9.:]+' | sort | uniq -c"
run "docker exec c1 cqlsh -e \"CONSISTENCY QUORUM; TRACING ON; UPDATE shop.stock SET units = 3 WHERE sku = 'KB-101' IF units = 4;\" | grep -oE 'Sending [A-Z0-9_]+ message to /[0-9.:]+' | sort | uniq -c"
