#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of nosql-operations, as a script
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
# with three copies, as lesson 17 left it. None of that is quoted here. The two
# files fill.cql and drain.cql are written by the loops tombstones.md shows.
#
# THE RESURRECTION IS REAL AND TWO SETTINGS WERE SHORTENED TO SEE IT IN MINUTES:
# the table `wishlist` is created with gc_grace_seconds = 60 instead of the
# default 864000 (ten days), and hinted handoff is switched off on every node
# with `nodetool disablehandoff`, standing in for a node that stayed down longer
# than max_hint_window (three hours). The lesson says both. The `sleep 70` is
# typed, and is the wait past gc_grace_seconds.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
quiet "$(from ../le-49a23d7k/ring-and-partitions.md 'for n in 1 2 3; do')"
quiet 'ready_cassandra c1 3'
quiet "docker exec c1 cqlsh -e \"CREATE KEYSPACE shop WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 3};\""

block memtable
session 'docker exec -it c1 cqlsh' <<'S'
CREATE TABLE shop.baskets (customer text, sku text, qty int, PRIMARY KEY (customer, sku));
INSERT INTO shop.baskets (customer, sku, qty) VALUES ('ana@example.com', 'KB-101', 1);
INSERT INTO shop.baskets (customer, sku, qty) VALUES ('ana@example.com', 'CB-012', 2);
exit
S
run 'docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/"'
run 'docker exec c1 nodetool flush shop baskets'
run 'docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/"'

block more-sstables
run "docker exec c1 cqlsh -e \"INSERT INTO shop.baskets (customer, sku, qty) VALUES ('bruno@example.com', 'MN-330', 1);\""
run 'docker exec c1 nodetool flush shop baskets'
run "docker exec c1 cqlsh -e \"UPDATE shop.baskets SET qty = 3 WHERE customer = 'ana@example.com' AND sku = 'CB-012';\""
run 'docker exec c1 nodetool flush shop baskets'
run 'docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"'
run 'docker exec c1 nodetool tablestats shop.baskets | grep "SSTable count"'

block compact
run 'docker exec c1 nodetool compact shop baskets'
run 'docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"'
run 'docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/baskets-*/*Data.db"'

block strategy
run 'docker exec c1 cqlsh -e "DESCRIBE TABLE shop.baskets" | grep -E "compaction|gc_grace"'
run 'docker exec c1 grep -A2 "^default_compaction" /etc/cassandra/cassandra_latest.yaml'

block tombstone
run "docker exec c1 cqlsh -e \"DELETE FROM shop.baskets WHERE customer = 'ana@example.com' AND sku = 'KB-101';\""
run 'docker exec c1 nodetool flush shop baskets'
run 'docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"'
run 'docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/baskets-*/nb-5-big-Data.db"'

block queue
run "docker exec c1 cqlsh -e \"CREATE TABLE shop.outbox (queue text, id int, body text, PRIMARY KEY (queue, id));\""
first=$(grep -m1 '^for i in $(seq 1 1500)' "$LESSON/tombstones.md")
run "$(from tombstones.md "$first")"
run 'wc -l fill.cql drain.cql'
run 'docker exec -i c1 cqlsh < fill.cql'
run 'docker exec -i c1 cqlsh < drain.cql'
session 'docker exec -it c1 cqlsh' <<'S'
SELECT id, body FROM shop.outbox WHERE queue = 'emails';
exit
S
run "docker exec c1 cqlsh -e \"TRACING ON; SELECT id FROM shop.outbox WHERE queue = 'emails';\" | grep -oE 'Read [0-9]+ live rows and [0-9]+ tombstone cells'"
run 'docker exec c1 grep -E "^tombstone_(warn|failure)_threshold" /etc/cassandra/cassandra.yaml'

block setup
session 'docker exec -it c1 cqlsh' <<'S'
CREATE TABLE shop.wishlist (customer text, sku text, PRIMARY KEY (customer, sku)) WITH gc_grace_seconds = 60;
CONSISTENCY ALL
INSERT INTO shop.wishlist (customer, sku) VALUES ('ana@example.com', 'KB-101');
INSERT INTO shop.wishlist (customer, sku) VALUES ('ana@example.com', 'MN-330');
exit
S
run 'for n in c1 c2 c3; do docker exec $n nodetool disablehandoff; done'
run 'docker exec c1 nodetool statushandoff'

block delete
run 'docker stop c3'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY QUORUM
DELETE FROM shop.wishlist WHERE customer = 'ana@example.com' AND sku = 'MN-330';
SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';
exit
S

block purge
run 'sleep 70'
run 'for n in c1 c2; do docker exec $n nodetool flush shop wishlist; docker exec $n nodetool compact shop wishlist; done'
run 'docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/wishlist-*/*Data.db"'

block return
run 'docker start c3'
run "$(from the-delete-that-comes-back.md 'until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done')"
quiet 'ready_cassandra c1 3'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY ONE
SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';
exit
S
run 'docker exec c1 nodetool repair -full shop wishlist | grep -E "Starting repair|Repair completed"'
session 'docker exec -it c1 cqlsh' <<'S'
CONSISTENCY ONE
SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';
exit
S
