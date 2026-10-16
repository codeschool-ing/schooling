#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of db-performance, as a script that
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
# STAGED: a CHECKPOINT and one full read of orders run first, unprinted, so
# that no transcript carries the one-off writes a freshly copied database makes
# on its first read. In the forcing-to-compare section each EXPLAIN ANALYZE is
# typed twice and only the second run is printed (`#quiet` lines), so that the
# two plans being compared are both warm; the lesson says so.
# Every setting is changed with SET, for the session only. No row changes.
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
lab as "psql -qX market -c 'CHECKPOINT' -c 'SELECT count(*) FROM orders' -c 'CHECKPOINT'" >/dev/null

OFF="SET max_parallel_workers_per_gather = 0;"
DAY="SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';"
MONTH="SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-07-01';"
YEAR="SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01';"
C100="SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1000 AND 1100;"
C20K="SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;"
C60K="SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 60000;"

block seq-serial
printf "%s\nEXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE total_cents > 40000;\n" "$OFF" | session market

block seq-parallel
printf "EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE total_cents > 40000;\n" | session market

block seq-small
printf "SHOW min_parallel_table_scan_size;\nSELECT pg_size_pretty(pg_relation_size('products'));\nEXPLAIN SELECT count(*) FROM products WHERE price_cents > 20000;\n" | session market

block index-one
printf "EXPLAIN ANALYZE SELECT * FROM orders WHERE id = 42;\n" | session market

block index-day
printf "%s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$DAY" | session market

block correlation
printf "SELECT attname, correlation FROM pg_stats WHERE tablename = 'orders' AND attname IN ('placed_at', 'customer_id', 'seller_id');\n" | session market

block index-scattered
printf "%s\nSET enable_bitmapscan = off;\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$C100" | session market

block bitmap-few
printf "%s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$C100" | session market

block bitmap-lossy
printf "%s\nEXPLAIN (ANALYZE, BUFFERS) %s\nSET work_mem = '64kB';\nEXPLAIN %s\nSET enable_seqscan = off;\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$C20K" "$C20K" "$C20K" | session market

block flip-dates
printf "EXPLAIN %s\nEXPLAIN %s\nEXPLAIN %s\n" "$DAY" "$MONTH" "$YEAR" | session market

block flip-customers
printf "EXPLAIN %s\nEXPLAIN %s\nEXPLAIN %s\n" "$C100" "$C20K" "$C60K" | session market

block force-year
printf "#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\nSET enable_seqscan = off;\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$YEAR" "$YEAR" "$YEAR" "$YEAR" | session market

block force-customers
printf "%s\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\nSET enable_bitmapscan = off;\n#quiet EXPLAIN ANALYZE %s\nEXPLAIN (ANALYZE, BUFFERS) %s\n" "$OFF" "$C20K" "$C20K" "$C20K" "$C20K" | session market

block penalty
printf "SET enable_seqscan = off;\nEXPLAIN SELECT * FROM products WHERE title LIKE '%%lamp%%';\n" | session market
