#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 5 and every later lesson start: shop loaded and
# analysed. The stale statistics are made on a copy of orders, orders_copy,
# with autovacuum switched off for that one table so that no automatic
# analysis arrives before the plan is read; the lesson says so and why. The
# copy is dropped, the statistics target put back and shop analysed again by
# the end, so the database is left as it was found.
#
# ANALYZE reads a random sample, so the frequencies and the n_distinct
# estimates move in their last digits between runs, and the prose quotes the
# numbers of the final run. The autoanalyze section waits, silently, for the
# autovacuum launcher to reach the table; it takes up to a minute.
#
# STAGED: nothing.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
export LAB_NAME=${LAB_NAME:-db}

lab reset 16

block knows
session shop <<'EOF'
SELECT relname, reltuples, relpages FROM pg_class WHERE relname IN ('orders', 'customers');
SELECT attname, null_frac, n_distinct FROM pg_stats WHERE tablename = 'orders';
SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';
EXPLAIN SELECT * FROM orders WHERE status = 'cancelled';
EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
EOF

block stale-copy
session shop <<'EOF'
CREATE TABLE orders_copy (LIKE orders INCLUDING ALL);
ALTER TABLE orders_copy SET (autovacuum_enabled = off);
CREATE INDEX orders_copy_status ON orders_copy (status);
INSERT INTO orders_copy (customer_id, status, total_cents, created_at) SELECT customer_id, status, total_cents, created_at FROM orders;
ANALYZE orders_copy;
EOF

block stale-load
session shop <<'EOF'
INSERT INTO orders_copy (customer_id, status, total_cents, created_at) SELECT 1 + (i * 7919::bigint) % 50000, 'pending', 1000, timestamptz '2026-09-01 00:00-03' + i * interval '1 second' FROM generate_series(1, 300000) AS i;
EXPLAIN ANALYZE SELECT c.country, count(*) FROM orders_copy o JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY c.country;
EOF

block stale-why
session shop <<'EOF'
SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders_copy' AND attname = 'status';
SELECT n_live_tup, n_mod_since_analyze, last_analyze FROM pg_stat_user_tables WHERE relname = 'orders_copy';
EOF

block stale-fixed
session shop <<'EOF'
ANALYZE orders_copy;
EXPLAIN ANALYZE SELECT c.country, count(*) FROM orders_copy o JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY c.country;
EOF

block auto-settings
session shop <<'EOF'
SELECT name, setting FROM pg_settings WHERE name IN ('autovacuum_analyze_threshold', 'autovacuum_analyze_scale_factor', 'autovacuum_naptime');
SELECT reltuples, 50 + 0.1 * reltuples AS analyze_after FROM pg_class WHERE relname = 'orders_copy';
EOF

block auto-run
session shop <<'EOF'
UPDATE orders_copy SET status = 'paid' WHERE status = 'pending';
ALTER TABLE orders_copy RESET (autovacuum_enabled);
SELECT now()::time(0), n_mod_since_analyze, last_analyze::time(0), last_autoanalyze::time(0) FROM pg_stat_user_tables WHERE relname = 'orders_copy';
EOF
lab as 'until [ "$(psql -XAtc "SELECT last_autoanalyze IS NOT NULL FROM pg_stat_user_tables WHERE relname = '"'"'orders_copy'"'"'" shop)" = t ]; do sleep 2; done'
session shop <<'EOF'
SELECT now()::time(0), n_mod_since_analyze, last_analyze::time(0), last_autoanalyze::time(0) FROM pg_stat_user_tables WHERE relname = 'orders_copy';
DROP TABLE orders_copy;
EOF

block target
session shop <<'EOF'
SHOW default_statistics_target;
\timing on
ANALYZE VERBOSE orders;
ALTER TABLE orders ALTER COLUMN total_cents SET STATISTICS 1000;
ANALYZE VERBOSE orders;
\timing off
SELECT attname, attstattarget FROM pg_attribute WHERE attrelid = 'orders'::regclass AND attnum > 0;
SELECT attname, array_length(histogram_bounds, 1) AS bounds FROM pg_stats WHERE tablename = 'orders' AND attname IN ('customer_id', 'total_cents');
ALTER TABLE orders ALTER COLUMN total_cents SET STATISTICS -1;
ANALYZE orders;
EOF

block restore
on 'pg_dump -Fc -f shop.dump shop'
on 'createdb shop_restore'
on 'pg_restore -d shop_restore shop.dump'
on 'psql shop_restore -c "SELECT count(*) FROM pg_stats WHERE schemaname = '"'"'public'"'"';"'
on 'psql shop_restore -c "EXPLAIN SELECT * FROM orders WHERE status = '"'"'cancelled'"'"';"'

block stages
on 'vacuumdb --analyze-in-stages -d shop_restore'
on 'psql shop_restore -c "EXPLAIN SELECT * FROM orders WHERE status = '"'"'cancelled'"'"';"'
on 'dropdb shop_restore'
on 'rm shop.dump'

lab down
