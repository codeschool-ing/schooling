#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset, which is what the student's
# ~/reset-market.sh does). The workload is taken out of lesson 2's
# a-workload.md and run as it is printed there. Each pgbench run's output is
# cut down to the lines the lesson reads, with the grep or sed shown in the
# command itself.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
onw() { printf 'ana@vm:~/workload$ %s\n' "$*"; lab as "cd ~/workload && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
python3 "$FENCE" ../le-9kwvr0x4/a-workload.md 'mkdir -p ~/workload' | lab as 'bash' >/dev/null
W="-f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1"
CUT="sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed"

block plan-before
session market <<'LINES'
EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
LINES

block runs-before
for i in 1 2 3; do onw "pgbench -n -c 8 -j 4 -T 30 $W market | $CUT"; done

block before-stats
session market <<'LINES'
SELECT calls, round(mean_exec_time::numeric, 3) AS mean_ms, round(total_exec_time) AS total_ms FROM pg_stat_statements WHERE query LIKE 'SELECT id, placed_at%';
SELECT pg_stat_statements_reset();
LINES

block index
session market <<'LINES'
CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at DESC);
SELECT pg_size_pretty(pg_relation_size('orders_customer_placed_idx')) AS new_index, pg_size_pretty(pg_relation_size('orders_customer_id_idx')) AS old_index;
LINES

block plan-after
session market <<'LINES'
EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
LINES

block runs-after
for i in 1 2 3; do onw "pgbench -n -c 8 -j 4 -T 30 $W market | $CUT"; done

block after-stats
session market <<'LINES'
SELECT calls, round(mean_exec_time::numeric, 3) AS mean_ms, round(total_exec_time) AS total_ms FROM pg_stat_statements WHERE query LIKE 'SELECT id, placed_at%';
LINES

block drop
session market <<'LINES'
SELECT pg_get_indexdef('orders_customer_placed_idx'::regclass);
DROP INDEX orders_customer_placed_idx;
LINES
