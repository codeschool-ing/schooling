#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# What is staged, none of it quoted here: the network `nosql` (lesson 1); the
# three nodes, started by the loop lesson 16 shows and taken out of its fence;
# the keyspace and orders of lesson 16, loaded from lesson 16's own orders.cql
# while the keyspace had one copy, then the ALTER KEYSPACE to three copies that
# lesson 17 runs, with no repair after it, exactly as a student who followed
# both lessons has them; and lesson 17's table `stock` with its four products,
# written at ALL.
#
# Two replicas are made to disagree on purpose, by the commands shown: hinted
# handoff is switched off on c1 and c2 with `nodetool disablehandoff` while c3
# is stopped, so that nothing replays the writes it missed.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
quiet "$(from ../le-49a23d7k/ring-and-partitions.md 'for n in 1 2 3; do')"
quiet 'ready_cassandra c1 3'
from ../le-49a23d7k/ring-and-partitions.md 'CREATE KEYSPACE shop' > orders.cql
quiet 'docker exec -i c1 cqlsh < orders.cql'
quiet "docker exec c1 cqlsh -e \"ALTER KEYSPACE shop WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 3};\""
quiet "docker exec c1 cqlsh -e \"CREATE TABLE shop.stock (sku text PRIMARY KEY, name text, units int);\""
quiet "docker exec c1 cqlsh -e \"CONSISTENCY ALL; INSERT INTO shop.stock (sku, name, units) VALUES ('KB-101', 'Mechanical keyboard', 5); INSERT INTO shop.stock (sku, name, units) VALUES ('MS-204', 'Wireless mouse', 12); INSERT INTO shop.stock (sku, name, units) VALUES ('MN-330', '27-inch monitor', 1); INSERT INTO shop.stock (sku, name, units) VALUES ('CB-012', 'USB-C cable', 40);\""
rm -f orders.cql

block hint-window
run 'docker exec c1 nodetool statushandoff'
run 'docker exec c1 nodetool getmaxhintwindow'

block hints
run 'docker stop c3'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY QUORUM
UPDATE shop.stock SET units = 11 WHERE sku = 'MS-204';
UPDATE shop.stock SET units = 39 WHERE sku = 'CB-012';
exit
S
quiet 'until docker exec c1 ls /var/lib/cassandra/hints | grep -q hints; do sleep 2; done'
run 'docker exec c1 ls -l /var/lib/cassandra/hints'
run 'docker exec c1 nodetool listpendinghints'
run 'docker exec c1 nodetool status shop | grep -E "^(UN|DN)"'

block replay
run 'docker start c3'
run "$(from ../le-3r9z7q9z/the-delete-that-comes-back.md 'until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done')"
quiet 'ready_cassandra c1 3'
quiet 'until docker logs c1 2>&1 | grep -q "Finished hinted handoff"; do sleep 2; done'
run 'docker logs c1 2>&1 | grep -E "Finished hinted handoff|Deleted hint file"'
run 'docker exec c1 ls -l /var/lib/cassandra/hints'

block diverge
run 'for n in c1 c2; do docker exec $n nodetool disablehandoff; done'
run 'docker stop c3'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY QUORUM
UPDATE shop.stock SET units = 4 WHERE sku = 'KB-101';
exit
S
run 'docker start c3'
run "$(from ../le-3r9z7q9z/the-delete-that-comes-back.md 'until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done')"
quiet 'ready_cassandra c1 3'
run 'for n in c1 c2; do docker exec $n nodetool enablehandoff; done'

block read-repair
run "docker exec c1 cqlsh -e \"CONSISTENCY ALL; TRACING ON; SELECT units FROM shop.stock WHERE sku = 'KB-101';\" | grep -oE 'units|^ +[0-9]+$|reading (digest|data) from /[0-9.:]+|Digest mismatch|Sending read-repair-mutation to [^ ]+|READ_REPAIR_RSP message received from /[0-9.:]+'"
run "docker exec c1 cqlsh -e \"CONSISTENCY ALL; TRACING ON; SELECT units FROM shop.stock WHERE sku = 'KB-101';\" | grep -oE 'units|^ +[0-9]+$|reading (digest|data) from /[0-9.:]+|Digest mismatch|Sending read-repair-mutation to [^ ]+|READ_REPAIR_RSP message received from /[0-9.:]+'"

block diverge-more
run 'for n in c1 c2; do docker exec $n nodetool disablehandoff; done'
run 'docker stop c3'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY QUORUM
UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330';
UPDATE shop.stock SET units = 10 WHERE sku = 'MS-204';
exit
S
run 'docker start c3'
run "$(from ../le-3r9z7q9z/the-delete-that-comes-back.md 'until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done')"
quiet 'ready_cassandra c1 3'
run 'for n in c1 c2; do docker exec $n nodetool enablehandoff; done'

block repair
run 'docker exec c1 nodetool repair -full shop | sed -E "s/for range \[.*\] finished/for range [...] finished/"'
run 'docker logs --since 1m c1 2>&1 | grep -oE "(Requesting merkle trees|Received merkle tree|Created [0-9]+ sync tasks|Endpoints .* out of sync|Performing streaming repair|shop\.[a-z_]+ is fully synced).*"'

block repair-again
run 'docker exec c1 nodetool repair -full shop stock | grep -E "Starting repair|Repair completed"'
run 'docker logs --since 20s c1 2>&1 | grep -oE "(Created [0-9]+ sync tasks|shop\.[a-z_]+ is fully synced).*"'

block incremental
run 'docker exec c1 nodetool tablestats shop.stock | grep -E "Percent repaired|Bytes (un)?repaired"'
run 'docker exec c1 nodetool repair shop stock | grep -E "Starting repair|Repair completed"'
run 'docker exec c1 nodetool tablestats shop.stock | grep -E "Percent repaired|Bytes (un)?repaired"'
run 'docker exec c1 sh -c "/opt/cassandra/tools/bin/sstablemetadata /var/lib/cassandra/data/shop/stock-*/*Data.db | grep -E \"^SSTable:|Repaired at\""'

block auto-repair
run 'docker logs c1 2>&1 | grep -i "auto-repair"'
