#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where every lesson from 3 on starts (lab.sh reset): market as a
# copy of market_base, pg_stat_statements and orders_seller_id_idx added, the
# server's configuration as apt left it.
#
# STAGED: "drop the cache" in the buffers section is run as root on the
# computer hosting the container, because a container cannot write to
# /proc/sys/vm/drop_caches. In a virtual machine the command printed does it.
# Nothing in this lesson changes a row for good: the DELETE is rolled back.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset

DASH="SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY 1 ORDER BY 1;"

block explain-plan
printf "EXPLAIN SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;\n" | session market

block explain-delete
printf "EXPLAIN DELETE FROM order_lines WHERE order_id = 7;\nSELECT count(*) FROM order_lines WHERE order_id = 7;\n" | session market

block startup
printf "SET max_parallel_workers_per_gather = 0;\nEXPLAIN SELECT id, placed_at, total_cents FROM orders ORDER BY placed_at LIMIT 10;\nEXPLAIN SELECT id, placed_at, total_cents FROM orders ORDER BY total_cents LIMIT 10;\n" | session market

block dashboard-plan
printf "EXPLAIN %s\n" "$DASH" | session market

block analyze-join
printf "EXPLAIN ANALYZE SELECT p.title, l.quantity, l.price_cents FROM order_lines AS l JOIN products AS p ON p.id = l.product_id WHERE l.order_id = 1234567;\n" | session market

block analyze-sort
printf "SET max_parallel_workers_per_gather = 0;\nEXPLAIN ANALYZE SELECT id, placed_at, total_cents FROM orders ORDER BY total_cents LIMIT 10;\n" | session market

block analyze-parallel
printf "EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';\nSELECT count(*) FROM orders WHERE status = 'pending';\n" | session market

block to-client
printf "EXPLAIN ANALYZE SELECT * FROM order_lines WHERE order_id <= 400000;\n\\\\o /dev/null\nSELECT * FROM order_lines WHERE order_id <= 400000;\n\\\\o\n" | session market

block analyze-dml
printf "BEGIN;\nEXPLAIN ANALYZE DELETE FROM order_lines WHERE order_id = 7;\nSELECT count(*) FROM order_lines WHERE order_id = 7;\nROLLBACK;\nSELECT count(*) FROM order_lines WHERE order_id = 7;\n" | session market

block cold
on 'sudo systemctl restart postgresql'
printf '%s\n' 'ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"'
sync; echo 3 > /proc/sys/vm/drop_caches
printf 'ana@vm:~$ psql market\n'
printf "SET track_io_timing = on;\nEXPLAIN (ANALYZE, BUFFERS) %s\nEXPLAIN (ANALYZE, BUFFERS) %s\nEXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE status = 'pending';\nEXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE status = 'pending';\n" "$DASH" "$DASH" | session market

block relpages
printf "SELECT relname, relpages, reltuples FROM pg_class WHERE relname IN ('orders', 'order_lines', 'products', 'customers', 'sellers', 'events') ORDER BY relname;\nSELECT name, setting FROM pg_settings WHERE name IN ('seq_page_cost', 'random_page_cost', 'cpu_tuple_cost', 'cpu_index_tuple_cost', 'cpu_operator_cost');\n" | session market

block seqcost
printf "EXPLAIN SELECT * FROM orders;\nEXPLAIN SELECT * FROM orders WHERE total_cents > 0;\nSET cpu_tuple_cost = 0.02;\nEXPLAIN SELECT * FROM orders;\nRESET cpu_tuple_cost;\n" | session market

block aggcost
printf "SET max_parallel_workers_per_gather = 0;\nEXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';\n" | session market

# not quoted in the prose: the numbers the exercises ask the student to work out
block exercise-checks
printf "EXPLAIN SELECT * FROM products;\nEXPLAIN SELECT * FROM customers WHERE state = 'SP';\nEXPLAIN SELECT * FROM order_lines;\nEXPLAIN SELECT * FROM orders WHERE status = 'pending' AND total_cents > 100;\nSET max_parallel_workers_per_gather = 0;\nEXPLAIN SELECT * FROM orders WHERE status = 'pending' AND total_cents > 100;\n" | session market
