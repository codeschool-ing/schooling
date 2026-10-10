#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts from `market` as lesson 3 starts (lab.sh reset, which is what the
# student's ~/reset-market.sh does). The statistics in pg_stats at that point
# are the ones the VACUUM ANALYZE at the end of market.sql gathered, copied
# with the database, so the first four blocks read the same numbers on every
# run. The ANALYZE statements in the last two blocks take a new random sample,
# so their numbers move a little from run to run; the lesson quotes this run.
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

block target
session market <<'SQL'
SHOW default_statistics_target;
SQL

block orders
session market <<'SQL'
SELECT attname, null_frac, n_distinct, correlation FROM pg_stats WHERE tablename = 'orders' ORDER BY attname;
SELECT attname, null_frac, n_distinct FROM pg_stats WHERE tablename = 'events' ORDER BY attname;
SQL

block seller-mcv
session market <<'SQL'
\x on
SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'seller_id';
\x off
EXPLAIN SELECT * FROM orders WHERE seller_id = 1;
EXPLAIN SELECT * FROM orders WHERE seller_id = 42;
EXPLAIN SELECT * FROM orders WHERE seller_id = 553;
SELECT seller_id, count(*) FROM orders WHERE seller_id IN (1, 42, 553) GROUP BY seller_id ORDER BY seller_id;
SQL

block status
session market <<'SQL'
SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';
SELECT status, count(*) FROM orders GROUP BY status ORDER BY count(*) DESC;
SQL

block bounds
session market <<'SQL'
SELECT n, b FROM pg_stats, unnest(histogram_bounds::text::timestamptz[]) WITH ORDINALITY AS u(b, n) WHERE tablename = 'orders' AND attname = 'placed_at' AND (n <= 3 OR n IN (12, 13) OR n >= 99);
EXPLAIN SELECT * FROM orders WHERE placed_at < '2024-01-01';
SELECT count(*) FROM orders WHERE placed_at < '2024-01-01';
EXPLAIN SELECT * FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
SQL

block correlation
session market <<'SQL'
EXPLAIN SELECT * FROM orders WHERE placed_at >= '2025-12-01';
EXPLAIN SELECT * FROM orders WHERE customer_id <= 10000;
SQL

block distinct
session market <<'SQL'
SELECT attname, n_distinct FROM pg_stats WHERE tablename = 'order_lines' ORDER BY attname;
SELECT count(DISTINCT order_id) FROM order_lines;
EXPLAIN SELECT order_id, count(*) FROM order_lines GROUP BY order_id;
SQL

block target-1000
session market <<'SQL'
ALTER TABLE order_lines ALTER COLUMN order_id SET STATISTICS 1000;
ANALYZE order_lines;
SELECT n_distinct FROM pg_stats WHERE tablename = 'order_lines' AND attname = 'order_id';
SQL

block override
session market <<'SQL'
ALTER TABLE order_lines ALTER COLUMN order_id SET (n_distinct = -0.4);
ANALYZE order_lines;
SELECT n_distinct FROM pg_stats WHERE tablename = 'order_lines' AND attname = 'order_id';
EXPLAIN SELECT order_id, count(*) FROM order_lines GROUP BY order_id;
SQL

block city-state
session market <<'SQL'
SELECT attname, (most_common_vals::text::text[])[5] AS value, most_common_freqs[5] AS freq FROM pg_stats WHERE tablename = 'customers' AND attname = 'city';
SELECT attname, (most_common_vals::text::text[])[4] AS value, most_common_freqs[4] AS freq FROM pg_stats WHERE tablename = 'customers' AND attname = 'state';
EXPLAIN SELECT * FROM customers WHERE city = 'Curitiba' AND state = 'PR';
SELECT count(*) FROM customers WHERE city = 'Curitiba' AND state = 'PR';
SQL

block create-stats
session market <<'SQL'
CREATE STATISTICS customers_city_state (dependencies, mcv) ON city, state FROM customers;
ANALYZE customers;
EXPLAIN SELECT * FROM customers WHERE city = 'Curitiba' AND state = 'PR';
SELECT statistics_name, attnames, dependencies FROM pg_stats_ext WHERE tablename = 'customers';
SQL

block group-by
session market <<'SQL'
EXPLAIN SELECT city, state, count(*) FROM customers GROUP BY city, state;
DROP STATISTICS customers_city_state;
CREATE STATISTICS customers_city_state (ndistinct, dependencies, mcv) ON city, state FROM customers;
ANALYZE customers;
EXPLAIN SELECT city, state, count(*) FROM customers GROUP BY city, state;
SQL
