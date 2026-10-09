#!/usr/bin/env bash
# The terminal and psql sessions quoted in lesson 10 of sql-databases, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up && sudo bash ../../lab.sh role   # once
#   sudo bash captures.sh
#
# It loads lesson 9's shop-large.sql, taken out of that lesson, and then walks
# the sections in order, because each leaves the database as the next one
# finds it: pg_stat_statements is switched on in the first, the index on
# orders.customer_id is built in explain-analyze, and sorts drops and rebuilds
# the one on placed_at. traffic.sql is taken out of finding-the-slow-ones.md.
#
# A line marked #quiet is typed into psql and left out of the transcript: it is
# `SET max_parallel_workers_per_gather = 0`, which explain.md tells the student
# to type once, and which every plan up to the last of the-joins is taken under.
#
# Timings are one run each, on a 4-core machine shared with other work, and
# they move from run to run; the lesson says so where it leans on one.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, 4 cores, TZ=UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
serial='#quiet SET max_parallel_workers_per_gather = 0;'
exec 9>/var/tmp/sql-capture.lock; flock 9

lab role >/dev/null 2>&1
lab exec 'createdb shop'
python3 "$FENCE" ../le-96rkt034/installing-postgresql.md 'cat > ~/.psqlrc' | lab exec bash
python3 "$FENCE" ../le-58t2yt2a/the-large-shop.md '-- shop-large.sql:' | lab exec 'cat > shop-large.sql'
python3 "$FENCE" finding-the-slow-ones.md '-- traffic.sql:' | lab exec 'cat > traffic.sql'
lab exec 'psql -q shop -f shop-large.sql >/dev/null'
lab exec "psql -qc 'ALTER SYSTEM RESET ALL' shop"

# --- finding-the-slow-ones ------------------------------------------------
block stat-statements-on
on "psql shop -c \"ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'\""
on 'sudo pg_ctlcluster 16 main restart'
on 'psql shop -c "CREATE EXTENSION pg_stat_statements"'

block traffic
on 'psql shop -f traffic.sql >/dev/null'

block by-total
session shop <<'SQL'
SELECT calls, round(total_exec_time::numeric) AS total_ms, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 5;
SQL

block by-mean
session shop <<'SQL'
SELECT calls, round(mean_exec_time::numeric, 1) AS mean_ms, left(query, 55) AS query FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 3;
SQL

block slow-log-on
session shop <<'SQL'
ALTER SYSTEM SET log_min_duration_statement = '100ms';
SELECT pg_reload_conf();
SQL

block slow-log-run
on 'psql shop -c "SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;" >/dev/null'
on 'psql shop -c "SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;" >/dev/null'
on 'sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log'

block slow-log-off
session shop <<'SQL'
ALTER SYSTEM RESET log_min_duration_statement;
SELECT pg_reload_conf();
SQL

# --- explain ----------------------------------------------------------------
block explain-seq
session shop <<'SQL'
SET max_parallel_workers_per_gather = 0;
EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
SQL

block explain-email
session shop <<SQL
$serial
EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
SQL

block explain-join
session shop <<SQL
$serial
EXPLAIN SELECT c.name, o.id, o.total FROM customers c JOIN orders o ON o.customer_id = c.id WHERE c.email = 'user42@example.com';
SQL

block explain-json
session shop <<SQL
$serial
EXPLAIN (FORMAT JSON) SELECT * FROM customers WHERE email = 'user42@example.com';
SQL

# --- explain-analyze: from a server that has just started --------------------
lab exec 'sudo pg_ctlcluster 16 main restart'
block analyze-cold
session shop <<SQL
$serial
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
SQL

block analyze-buffers
session shop <<SQL
$serial
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
SQL

block analyze-buffers-again
session shop <<SQL
$serial
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
SQL

block create-index
session shop <<'SQL'
CREATE INDEX ON orders (customer_id);
SQL

block analyze-index-buffers
session shop <<SQL
$serial
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 42;
SQL

block analyze-index
session shop <<SQL
$serial
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
SQL

# --- the-scans ----------------------------------------------------------------
for q in \
  "EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'paid';" \
  "EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';" \
  "EXPLAIN ANALYZE SELECT customer_id FROM orders WHERE customer_id = 42;" \
  "EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'cancelled';" \
  "EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending' AND placed_at >= DATE '2025-09-01';" \
  "EXPLAIN ANALYZE SELECT c.name, o.id, o.total FROM customers c JOIN orders o ON o.customer_id = c.id WHERE c.email = 'user42@example.com';" \
  "EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id WHERE o.status = 'pending';" \
  "EXPLAIN ANALYZE SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;" \
  "EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id;" \
; do
  block "q: $q"
  printf '%s\n%s\n' "$serial" "$q" | session shop
done

# --- the-joins: a merge join, made visible -----------------------------------
block merge
session shop <<SQL
$serial
SET enable_hashjoin = off;
EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id;
SQL

block parallel
session shop <<'SQL'
EXPLAIN ANALYZE SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
SQL

# --- estimates-against-actuals ------------------------------------------------
block date-function
printf '%s\n%s\n' "$serial" "EXPLAIN ANALYZE SELECT * FROM orders WHERE date(placed_at) = DATE '2025-03-01';" | session shop

block returns
python3 "$FENCE" estimates-against-actuals.md 'CREATE TABLE returns' | lab exec 'psql -q shop'
session shop <<SQL
$serial
EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
INSERT INTO returns (id, order_id, reason, opened_at) SELECT n, n * 5, (ARRAY['damaged', 'late', 'wrong item', 'changed mind'])[1 + n % 4], timestamptz '2025-01-01 00:00+00' + n * interval '1 minute' FROM generate_series(1, 200000) AS n;
EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
ANALYZE returns;
EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
SQL

# --- sorts-and-aggregates -------------------------------------------------------
block sorts
session shop <<SQL
$serial
DROP INDEX orders_placed_at_idx;
EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at LIMIT 10;
EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at;
CREATE INDEX ON orders (placed_at);
EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at LIMIT 10;
EXPLAIN ANALYZE SELECT status, count(*) FROM orders GROUP BY status;
EXPLAIN ANALYZE SELECT city, count(*) FROM customers GROUP BY city ORDER BY city;
SQL

# --- fixing-it ------------------------------------------------------------------
block fixing
session shop <<SQL
$serial
EXPLAIN ANALYZE SELECT * FROM customers WHERE lower(email) = 'user42@example.com';
EXPLAIN ANALYZE SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 500000;
EXPLAIN ANALYZE SELECT * FROM orders WHERE id > 500000 ORDER BY id LIMIT 20;
SQL
