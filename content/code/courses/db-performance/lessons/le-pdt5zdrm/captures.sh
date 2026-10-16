#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset: market as ~/reset-market.sh
# leaves it). Lesson 2's workload files are written again from lesson 2's own
# a-workload.md, as the student already has them in ~/workload, and
# ~/leftovers.sql is taken out of this lesson's the-write-tax.md and run as it
# is printed there.
#
# STAGED: nothing else. The pgbench runs are run from inside psql with \!, as
# the lesson shows, so that one window holds the WAL position before and after.
# Every timing and every byte count is from the run that produced this
# lesson's transcripts; other runs on the same machine differ by a few per cent.
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
python3 "$FENCE" ../le-9kwvr0x4/the-first-fix.md 'cat > ~/reset-market.sh' | lab as 'bash'
for f in the-write-tax.md:'cat > ~/leftovers.sql' unused.md:'cat > ~/unused-indexes.sql' \
         duplicates.md:'cat > ~/duplicate-indexes.sql' overlapping.md:'cat > ~/overlapping-indexes.sql'; do
  python3 "$FENCE" "${f%%:*}" "${f#*:}" | lab as 'bash'
done

MEASURE="CHECKPOINT;
SELECT pg_stat_reset();
SELECT pg_current_wal_lsn() AS before \\gset
\\! pgbench -n -c 4 -j 4 -t 5000 -f ~/workload/place-order.sql market
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal, round(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') / 20000) AS bytes_per_order;
SELECT n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'orders';"

SIZES="SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_index WHERE indrelid IN ('orders'::regclass, 'order_lines'::regclass) ORDER BY indrelid, indexrelid;"

block baseline
printf '%s\n' "$MEASURE" | session market

block leftovers
on 'psql market -f ~/leftovers.sql'

block sizes
printf '%s\n' "$SIZES" | session market

block after
printf '%s\n' "$MEASURE" | session market

block statreset
printf "SELECT pg_stat_reset();\n" | session market

block mix
onw 'pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market'

block idx-scan
printf "SELECT relname AS table, indexrelname AS index, idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_stat_user_indexes ORDER BY idx_scan, relname, indexrelname;\n" | session market

block stats-reset
printf "SELECT stats_reset FROM pg_stat_database WHERE datname = 'market';\nSELECT indexrelname AS index, idx_scan, last_idx_scan FROM pg_stat_user_indexes WHERE relname = 'orders' ORDER BY indexrelname;\n" | session market

block unused-query
on 'psql market -f unused-indexes.sql'

block report
printf "SELECT status, count(*) FROM orders WHERE placed_at >= '2025-11-01' AND placed_at < '2025-12-01' GROUP BY status;\n" | session market

block report-scan
printf "SELECT indexrelname AS index, idx_scan FROM pg_stat_user_indexes WHERE indexrelname LIKE 'orders_placed_at%%';\n" | session market

block duplicates
on 'psql market -f duplicate-indexes.sql'

block overlapping
on 'psql market -f overlapping-indexes.sql'

block composite
printf "BEGIN;\nDROP INDEX orders_seller_id_idx;\nEXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE seller_id = 42;\nSELECT count(*) FROM orders WHERE seller_id = 42;\nROLLBACK;\n" | session market

block save-defs
python3 "$FENCE" dropping-safely.md 'psql -XAt market' | lab as 'bash'
on 'cat ~/dropped-indexes.sql'

block in-transaction
printf "BEGIN;\nDROP INDEX CONCURRENTLY orders_total_cents_idx;\nROLLBACK;\nDROP INDEX CONCURRENTLY orders_pkey;\n" | session market

block drop
printf "DROP INDEX CONCURRENTLY orders_customer_idx;\nDROP INDEX CONCURRENTLY order_lines_product_id_idx1;\nDROP INDEX CONCURRENTLY orders_total_cents_idx;\nDROP INDEX CONCURRENTLY orders_seller_id_idx;\nDROP INDEX CONCURRENTLY orders_placed_at_status_idx;\nDROP INDEX CONCURRENTLY order_lines_order_id_idx;\n" | session market

block recreate
printf "CREATE INDEX CONCURRENTLY orders_total_cents_idx ON orders (total_cents);\nDROP INDEX CONCURRENTLY orders_total_cents_idx;\n" | session market

block final
printf '%s\n' "$MEASURE" | session market

block reset
on '~/reset-market.sh'
