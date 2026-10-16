#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts from `market` as lesson 3 starts (lab.sh reset, which is what the
# student's ~/reset-market.sh does). lab.sh reset removes ~/workload, so the
# workload is written again from lesson 2's a-workload.md; customer-orders.sql
# and place-order.sql are the files the pgbench runs use. The UPDATE in
# "dirty" stands in for the job that marks shipped orders delivered; nothing
# else touches orders between it and the VACUUM, and the table is far below
# autovacuum's thresholds, so no automatic VACUUM runs in between.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
onw() { printf 'ana@vm:~/workload$ %s\n' "$*"; lab as "cd ~/workload && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
python3 "$FENCE" ../le-9kwvr0x4/a-workload.md 'mkdir -p ~/workload' | lab as 'bash' >/dev/null

block ios
session market <<'SQL'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-12-01';
SQL

block allvisible
session market <<'SQL'
SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
SQL

block dirty
session market <<'SQL'
UPDATE orders SET status = 'delivered' WHERE status = 'shipped';
SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
SQL

block vacuum
session market <<'SQL'
VACUUM orders;
SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
SQL

block customer-before
session market <<'SQL'
EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
SQL
onw 'pgbench -n -c 8 -j 4 -T 10 -f customer-orders.sql market 2>&1 | grep -E "^(latency average|tps)"'

block include-missing
session market <<'SQL'
CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (status, total_cents);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
DROP INDEX orders_customer_placed_idx;
SQL

block include
session market <<'SQL'
CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (id, status, total_cents);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
SQL
onw 'pgbench -n -c 8 -j 4 -T 10 -f customer-orders.sql market 2>&1 | grep -E "^(latency average|tps)"'

block sizes
session market <<'SQL'
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders', 'orders_customer_id_idx', 'orders_customer_placed_idx');
SQL

block write-without
session market <<'SQL'
DROP INDEX orders_customer_placed_idx;
SELECT pg_stat_reset_single_table_counters('orders'::regclass);
SQL
onw 'pgbench -n -c 8 -j 4 -T 15 -f place-order.sql market 2>&1 | grep -E "^(latency average|tps)"'
session market <<'SQL'
SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
SQL

block write-with
session market <<'SQL'
CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (id, status, total_cents);
SELECT pg_stat_reset_single_table_counters('orders'::regclass);
SQL
onw 'pgbench -n -c 8 -j 4 -T 15 -f place-order.sql market 2>&1 | grep -E "^(latency average|tps)"'
session market <<'SQL'
SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';
SQL
