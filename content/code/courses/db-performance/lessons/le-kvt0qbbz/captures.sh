#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts from `market` as lesson 3 starts (lab.sh reset, which is what the
# student's ~/reset-market.sh does), whose statistics are the ones market.sql's
# VACUUM ANALYZE gathered. Every psql session sets max_parallel_workers_per_gather
# to 0, as the lesson tells the student to, so each plan is one process.
#
# STAGED: autovacuum (and with it autoanalyze) is switched off for `orders`
# before the bulk insert, exactly as the lesson shows, so that the stale
# statistics stay stale for as long as the lesson needs them. The insert draws
# its rows from setseed(0.6), so every run inserts the same 300,000 orders.
# The ANALYZE statements take a fresh random sample, so the numbers after them
# move a little from run to run; the lesson quotes this run.
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

block healthy
session market <<'SQL'
SET max_parallel_workers_per_gather = 0;
EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE seller_id = 42;
SQL

block ratio
session market <<'SQL'
#quiet SET max_parallel_workers_per_gather = 0;
EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN customers c ON c.id = o.customer_id WHERE c.city = 'Curitiba' AND c.state = 'PR';
SQL

block cascade-fresh
session market <<'SQL'
#quiet SET max_parallel_workers_per_gather = 0;
EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
SQL

block import
session market <<'SQL'
ALTER TABLE orders SET (autovacuum_enabled = off);
SELECT setseed(0.6);
INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) SELECT 1 + floor(random() * 200000)::int, 2 + floor(random() * 999)::int, timestamptz '2026-01-02 00:00-03' + random() * interval '1 day', 'pending', 500 + floor(random() * 50000)::int FROM generate_series(1, 300000);
SQL

block counters
session market <<'SQL'
SELECT n_live_tup, n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname = 'orders';
SELECT reltuples::bigint, relpages, pg_relation_size('orders') / 8192 AS pages_now FROM pg_class WHERE relname = 'orders';
SQL

block stale
session market <<'SQL'
#quiet SET max_parallel_workers_per_gather = 0;
EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
SQL

block cascade-stale
session market <<'SQL'
#quiet SET max_parallel_workers_per_gather = 0;
EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
SQL

block analyze
session market <<'SQL'
#quiet SET max_parallel_workers_per_gather = 0;
ANALYZE orders;
EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
SQL

block verbose
session market <<'SQL'
SHOW default_statistics_target;
ANALYZE VERBOSE orders;
ANALYZE VERBOSE events;
SQL

block auto
session market <<'SQL'
SELECT relname, n_mod_since_analyze, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE relname IN ('orders', 'events') ORDER BY relname;
SHOW autovacuum_analyze_threshold;
SHOW autovacuum_analyze_scale_factor;
ALTER TABLE orders RESET (autovacuum_enabled);
SQL
