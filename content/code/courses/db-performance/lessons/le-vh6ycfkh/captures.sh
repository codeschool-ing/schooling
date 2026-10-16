#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of db-performance, as a script that
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
# STAGED: a CHECKPOINT and one full read of orders and order_lines run first,
# unprinted, so that no transcript carries the one-off writes a freshly copied
# database makes on its first read. Where two plans are compared, each
# EXPLAIN ANALYZE is typed twice and only the second run is printed (`#quiet`
# lines), so both are warm; the lesson says so. Every setting is changed with
# SET, for the session only. No row changes.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
lab() { bash "$LAB" "$@"; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
lab as "psql -qX market -c 'CHECKPOINT' -c 'SELECT count(*) FROM orders' -c 'SELECT count(*) FROM order_lines' -c 'CHECKPOINT'" >/dev/null

OFF="SET max_parallel_workers_per_gather = 0;"
CUST="SELECT o.id, o.placed_at, l.product_id, l.quantity FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.customer_id = 4242;"
STATE="SELECT c.state, count(*) FROM orders AS o JOIN customers AS c ON c.id = o.customer_id GROUP BY c.state;"
SELLER="SELECT p.seller_id, sum(l.quantity * l.price_cents) AS revenue FROM order_lines AS l JOIN products AS p ON p.id = l.product_id GROUP BY p.seller_id ORDER BY revenue DESC LIMIT 5;"
FIRST="SELECT count(*) FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.id <= 200000;"
FLIP="SELECT c.name, o.id, o.total_cents FROM customers AS c JOIN orders AS o ON o.customer_id = c.id WHERE c.id <="

block nested
printf "%s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$CUST" | session market

block hash-state
printf "%s\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$STATE" "$STATE" | session market

block hash-workmem
printf "%s\nSET work_mem = '1MB';\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\nSET work_mem = '32MB';\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\nRESET work_mem;\nSHOW hash_mem_multiplier;\n" "$OFF" "$STATE" "$STATE" "$STATE" "$STATE" | session market

block hash-products
printf "%s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$SELLER" | session market

block merge
printf "%s\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\nSET enable_hashjoin = off;\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$FIRST" "$FIRST" "$FIRST" "$FIRST" | session market

block merge-price
printf "%s\nSET random_page_cost = 1.1;\nEXPLAIN %s\n" "$OFF" "$FIRST" | session market

block flip
printf "%s\nEXPLAIN %s 10;\nEXPLAIN %s 1000;\nEXPLAIN %s 20000;\n" "$OFF" "$FLIP" "$FLIP" "$FLIP" | session market
