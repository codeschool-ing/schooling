#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset). shard-table.sql and
# coordinator.sql are taken out of this lesson's own across-shards.md and run
# as they are printed there.
#
# STAGED: the two shards are two databases on the same server, standing in for
# two machines, and the lesson says so. The failed commits in across-shards
# are real: a deferred constraint fails at COMMIT on one shard, once on each,
# and the coordinator commits the shards one after the other in an order it
# chooses, so one of the two transactions leaves its other half committed.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
lab as 'dropdb --if-exists shard1; dropdb --if-exists shard2; rm -f ~/shard-table.sql ~/coordinator.sql' >/dev/null 2>&1

block years
printf "SELECT extract(year FROM placed_at) AS year, count(*) FROM orders GROUP BY 1 ORDER BY 1;\nSELECT pg_size_pretty(pg_total_relation_size('orders')) AS orders, pg_size_pretty(pg_database_size('market')) AS market;\n" | session market

block hot
printf "SELECT seller_id, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY seller_id ORDER BY count(*) DESC LIMIT 3;\nSELECT seller_id %% 4 AS shard, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY 1 ORDER BY 1;\nSELECT customer_id %% 4 AS shard, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY 1 ORDER BY 1;\nSELECT max(n) AS busiest_customer FROM (SELECT count(*) AS n FROM orders GROUP BY customer_id) AS per_customer;\n" | session market

python3 "$FENCE" across-shards.md 'cat > ~/shard-table.sql' | lab as 'bash'
python3 "$FENCE" across-shards.md 'cat > ~/coordinator.sql' | lab as 'bash'

block shards
on 'createdb shard1'
on 'createdb shard2'
on 'psql -q shard1 -f shard-table.sql'
on 'psql -q shard2 -f shard-table.sql'
on "psql market -c \"ALTER ROLE ana PASSWORD 'shard-lab'\""
on 'psql market -f coordinator.sql'

block load
printf "INSERT INTO sharded_orders SELECT * FROM orders;\nANALYZE sharded_orders;\n" | session market
on "psql shard1 -c 'SELECT count(*) FROM orders'"
on "psql shard2 -c 'SELECT count(*) FROM orders'"

block route
printf "EXPLAIN (VERBOSE, COSTS OFF) SELECT id, placed_at, status FROM sharded_orders WHERE customer_id = 42;\nEXPLAIN (VERBOSE, COSTS OFF) SELECT id, placed_at, status FROM sharded_orders WHERE seller_id = 42;\nSELECT count(*) FROM sharded_orders WHERE customer_id = 42;\nSELECT count(*) FROM sharded_orders WHERE seller_id = 42;\n" | session market

block aggregate
printf "EXPLAIN (VERBOSE, COSTS OFF) SELECT status, count(*) FROM sharded_orders GROUP BY status;\nSELECT status, count(*) FROM sharded_orders GROUP BY status;\nSELECT status, count(*) FROM orders GROUP BY status;\n" | session market

block pushdown
printf "SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;\nSET enable_partitionwise_aggregate = on;\nEXPLAIN (VERBOSE, COSTS OFF) SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;\nSELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;\n" | session market

block commit
on "for s in shard1 shard2; do psql \$s -c 'ALTER TABLE orders ADD CONSTRAINT one_order_per_instant UNIQUE (customer_id, placed_at) DEFERRABLE INITIALLY DEFERRED'; done"
printf "BEGIN;\nINSERT INTO sharded_orders VALUES (2000001, 1, 7, now(), 'pending', 1990);\nINSERT INTO sharded_orders SELECT 2000002, customer_id, 7, placed_at, 'pending', 1990 FROM sharded_orders WHERE customer_id = 3 ORDER BY id LIMIT 1;\nCOMMIT;\nBEGIN;\nINSERT INTO sharded_orders VALUES (2000003, 3, 7, now(), 'pending', 1990);\nINSERT INTO sharded_orders SELECT 2000004, customer_id, 7, placed_at, 'pending', 1990 FROM sharded_orders WHERE customer_id = 1 ORDER BY id LIMIT 1;\nCOMMIT;\nSELECT tableoid::regclass AS shard, id, customer_id FROM sharded_orders WHERE id > 2000000;\n" | session market

block unique
printf "CREATE UNIQUE INDEX ON sharded_orders (id);\nINSERT INTO sharded_orders VALUES (1, 3, 7, now(), 'pending', 1990);\nSELECT tableoid::regclass AS shard, id, customer_id FROM sharded_orders WHERE id = 1;\n" | session market

block move
printf "SELECT count(*) FILTER (WHERE satisfies_hash_partition('sharded_orders'::regclass, 4, 2, customer_id) OR satisfies_hash_partition('sharded_orders'::regclass, 4, 3, customer_id)) AS moving, count(*) AS total FROM orders;\n" | session market

block schema
on "for s in shard1 shard2; do psql \$s -c 'ALTER TABLE orders ADD COLUMN coupon text'; done"
printf "SELECT coupon FROM sharded_orders WHERE customer_id = 42;\nALTER TABLE sharded_orders ADD COLUMN coupon text;\nSELECT count(coupon) FROM sharded_orders WHERE customer_id = 42;\n" | session market

block cleanup
on 'dropdb shard1'
on 'dropdb shard2'
on "psql market -c 'ALTER ROLE ana PASSWORD NULL'"
lab reset
