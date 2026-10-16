#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts from `market` as lesson 1 leaves it (lab.sh reset) and the server
# configuration as apt leaves it. The workload files are taken out of this
# lesson's own a-workload.md and run as they are printed there.
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

lab reset bare
lab as 'rm -rf ~/workload'
python3 "$FENCE" a-workload.md 'mkdir -p ~/workload' | lab as 'bash' >/dev/null

block enable
printf "ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';\n" | session market
on 'sudo systemctl restart postgresql'
printf "CREATE EXTENSION pg_stat_statements;\n" | session market

block files
on 'ls ~/workload'

block run
onw 'pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market'

block top-total
printf "SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms, round(100 * total_exec_time / sum(total_exec_time) OVER ()) AS pct, left(regexp_replace(query, '\\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY total_exec_time DESC LIMIT 8;\n" | session market

block top-mean
printf "SELECT calls, round(mean_exec_time::numeric, 2) AS mean_ms, round(total_exec_time) AS total_ms, left(regexp_replace(query, '\\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY mean_exec_time DESC LIMIT 5;\n" | session market

block one-row
session market <<'LINES'
\x on
SELECT queryid, calls, total_exec_time, min_exec_time, max_exec_time, mean_exec_time, stddev_exec_time, rows, shared_blks_hit, shared_blks_read, query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') AND query LIKE '%date_trunc%';
LINES

block log
printf "ALTER SYSTEM SET log_min_duration_statement = '50ms';\nSELECT pg_reload_conf();\n" | session market
onw 'pgbench -n -c 4 -T 10 -f seller-dashboard.sql -f pending-count.sql market > /dev/null'
on 'sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log'

block december
printf "SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';\n" | session market

block fix
printf "SELECT pg_stat_statements_reset();\nCREATE INDEX orders_seller_id_idx ON orders (seller_id);\n" | session market
lab as "psql -qX market -c \"ALTER SYSTEM RESET log_min_duration_statement\" -c 'SELECT pg_reload_conf()'" >/dev/null
onw 'pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market'
printf "SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms, round(100 * total_exec_time / sum(total_exec_time) OVER ()) AS pct, left(regexp_replace(query, '\\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY total_exec_time DESC LIMIT 8;\n" | session market

block dealloc
printf "SHOW pg_stat_statements.max;\nSELECT dealloc, stats_reset FROM pg_stat_statements_info;\n" | session market

block reset-script
python3 "$FENCE" the-first-fix.md 'cat > ~/reset-market.sh' | lab as 'bash'
on '~/reset-market.sh'
printf "SELECT count(*) FROM orders;\n\\di orders*\n" | session market
