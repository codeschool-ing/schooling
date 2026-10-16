#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of db-performance, as a script that
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
# a-workload.md and capacity.sql out of this lesson's alerts.md, and both are
# run as they are printed there.
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
python3 "$FENCE" headroom.md 'cat > ~/workload/percentiles.sh' | lab as 'bash' 
W="-f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1"

block monthly
session market <<'LINES'
SELECT date_trunc('month', placed_at)::date AS month, count(*) AS orders FROM orders WHERE placed_at >= '2025-01-01' GROUP BY 1 ORDER BY 1;
LINES

block per-row
session market <<'LINES'
SELECT relname, reltuples::bigint AS rows, pg_size_pretty(pg_total_relation_size(oid)) AS with_indexes, round(pg_total_relation_size(oid) / reltuples) AS bytes_per_row FROM pg_class WHERE relname IN ('orders', 'order_lines', 'events') ORDER BY relname;
LINES

block disk
on 'df -h /var/lib/postgresql'

block max-tps
onw "pgbench -n -c 8 -j 4 -T 30 $W market | grep -E '^(tps|latency average)'"

block rated
for r in 300 600 900 1050; do
  onw "pgbench -n -c 8 -j 4 -T 30 -R $r $W market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'"
done

block percentiles
onw "pgbench -n -c 8 -j 4 -T 30 -R 600 -l --log-prefix=r600 $W market > /dev/null"
onw "pgbench -n -c 8 -j 4 -T 30 -R 1000 -l --log-prefix=r1000 $W market > /dev/null"
onw './percentiles.sh r600'
onw './percentiles.sh r1000'

block walls
session market <<'LINES'
SELECT count(*) AS connections, current_setting('max_connections') AS max FROM pg_stat_activity WHERE backend_type = 'client backend';
SELECT datname, age(datfrozenxid) AS xid_age, current_setting('autovacuum_freeze_max_age') AS freeze_max FROM pg_database WHERE datname = 'market';
SELECT sequencename, data_type, last_value, max_value, round(100.0 * last_value / max_value, 4) AS pct_used FROM pg_sequences ORDER BY pct_used DESC;
SELECT max(total_cents) AS largest_order, 2147483647 AS integer_limit FROM orders;
LINES

block capacity
python3 "$FENCE" alerts.md '-- capacity.sql:' | lab as 'cat > capacity.sql'
on 'psql market -f capacity.sql'
