#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts from `market` as lesson 3 starts (lab.sh reset, which is what the
# student's ~/reset-market.sh does). lab.sh reset removes ~/workload, so the
# workload is written again from lesson 2's a-workload.md; pending-count.sql
# is the file the pgbench runs use. carts.sql is taken out of this lesson's
# partial-unique.md: it is shown there as an annotated example, so its parts
# are joined back into the file the student copies.
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

block pending-before
onw 'pgbench -n -c 4 -j 4 -T 10 -f pending-count.sql market 2>&1 | grep -E "^(latency average|tps)"'
session market <<'SQL'
EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
SQL

block full-index
session market <<'SQL'
CREATE INDEX orders_status_idx ON orders (status);
EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
SQL

block partial-index
session market <<'SQL'
CREATE INDEX orders_pending_idx ON orders (placed_at) WHERE status = 'pending';
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders', 'orders_status_idx', 'orders_pending_idx');
DROP INDEX orders_status_idx;
EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
SQL
onw 'pgbench -n -c 4 -j 4 -T 10 -f pending-count.sql market 2>&1 | grep -E "^(latency average|tps)"'

block partial-limits
session market <<'SQL'
EXPLAIN SELECT id, placed_at FROM orders WHERE status = 'pending' ORDER BY placed_at LIMIT 20;
EXPLAIN SELECT count(*) FROM orders WHERE status = 'shipped';
PREPARE by_status(text) AS SELECT count(*) FROM orders WHERE status = $1;
SET plan_cache_mode = force_generic_plan;
EXPLAIN EXECUTE by_status('pending');
SQL

block carts
python3 - partial-unique.md <<'PY' | lab as 'cat > carts.sql'
import json, sys
src = open(sys.argv[1]).read().split('```schooling-example\n', 1)[1].split('\n```', 1)[0]
sys.stdout.write(''.join(p['code'] for p in json.loads(src)['parts']))
PY
on 'psql market -f carts.sql'

block carts-try
session market <<'SQL'
INSERT INTO carts (customer_id) VALUES (42);
INSERT INTO carts (customer_id) VALUES (42);
INSERT INTO carts (customer_id) VALUES (42) ON CONFLICT (customer_id) WHERE status = 'open' DO NOTHING;
UPDATE carts SET status = 'ordered' WHERE customer_id = 42 AND status = 'open';
INSERT INTO carts (customer_id) VALUES (42);
SELECT id, customer_id, status FROM carts ORDER BY id;
SQL

block lower
session market <<'SQL'
EXPLAIN ANALYZE SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
CREATE INDEX customers_lower_email_idx ON customers (lower(email));
EXPLAIN ANALYZE SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
ANALYZE customers;
EXPLAIN SELECT id, email FROM customers WHERE lower(email) = 'user42@example.com';
SELECT tablename, attname, n_distinct FROM pg_stats WHERE tablename = 'customers_lower_email_idx';
SQL

block immutable
session market <<'SQL'
CREATE INDEX orders_placed_date_idx ON orders (date(placed_at));
SELECT provolatile FROM pg_proc WHERE oid = 'date(timestamp with time zone)'::regprocedure;
SET TimeZone = 'UTC';
SELECT date(timestamptz '2025-06-01 22:30-03');
SET TimeZone = 'America/Sao_Paulo';
SELECT date(timestamptz '2025-06-01 22:30-03');
SQL

block local-date
session market <<'SQL'
CREATE INDEX orders_placed_date_idx ON orders (((placed_at AT TIME ZONE 'America/Sao_Paulo')::date));
EXPLAIN SELECT count(*) FROM orders WHERE (placed_at AT TIME ZONE 'America/Sao_Paulo')::date = '2025-06-01';
ANALYZE orders;
EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE (placed_at AT TIME ZONE 'America/Sao_Paulo')::date = '2025-06-01';
EXPLAIN SELECT count(*) FROM orders WHERE date(placed_at) = '2025-06-01';
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders_placed_at_idx', 'orders_placed_date_idx');
SQL
