#!/usr/bin/env bash
# The terminal and psql sessions quoted in lesson 11 of sql-databases, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up && sudo bash ../../lab.sh role   # once
#   sudo bash captures.sh
#
# It starts where lesson 10 leaves the student: lesson 9's shop-large.sql
# loaded, pg_stat_statements switched on the way lesson 10 shows, and the index
# on orders.customer_id that lesson 10 builds. page.sh is taken out of
# what-it-emits.md and run as printed there.
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
exec 9>/var/tmp/sql-capture.lock; flock 9

lab role >/dev/null 2>&1
lab exec 'createdb shop'
python3 "$FENCE" ../le-96rkt034/installing-postgresql.md 'cat > ~/.psqlrc' | lab exec bash
python3 "$FENCE" ../le-58t2yt2a/the-large-shop.md '-- shop-large.sql:' | lab exec 'cat > shop-large.sql'
python3 "$FENCE" what-it-emits.md '# page.sh:' | lab exec 'cat > page.sh'
lab exec 'psql -q shop -f shop-large.sql >/dev/null'
lab exec "psql -qc 'ALTER SYSTEM RESET ALL' shop"
lab exec "psql -qc \"ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'\" shop"
lab exec 'sudo pg_ctlcluster 16 main restart'
lab exec 'psql -q shop -c "CREATE EXTENSION pg_stat_statements" -c "CREATE INDEX ON orders (customer_id)"'

# --- what-it-emits and the-n-plus-one ------------------------------------------
block log-on
session shop <<'SQL'
SELECT pg_stat_statements_reset();
ALTER SYSTEM SET log_min_duration_statement = 0;
SELECT pg_reload_conf();
SQL

block page
on 'sh page.sh'
on "sudo grep 'statement: SELECT id,' /var/log/postgresql/postgresql-16-main.log | tail -n 51 | head -n 4"

block calls
session shop <<'SQL'
SELECT calls, left(query, 60) AS query FROM pg_stat_statements WHERE query LIKE 'SELECT id,%' ORDER BY calls DESC;
SQL

block log-off
session shop <<'SQL'
ALTER SYSTEM RESET log_min_duration_statement;
SELECT pg_reload_conf();
SQL

# --- loading-in-one-go -----------------------------------------------------------
block any-array
session shop <<'SQL'
SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3]) ORDER BY customer_id, placed_at;
SQL

block any-plan
session shop <<'SQL'
EXPLAIN ANALYZE SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
SQL

block left-join
session shop <<'SQL'
SELECT c.id, c.name, o.id AS order_id, o.total FROM customers c LEFT JOIN orders o ON o.customer_id = c.id WHERE c.id IN (1, 2, 3) ORDER BY c.id, o.id;
SQL

# --- parameters --------------------------------------------------------------------
block prepare
session shop <<'SQL'
PREPARE by_email (text) AS SELECT id, name FROM customers WHERE email = $1;
EXECUTE by_email('user42@example.com');
EXECUTE by_email('x'' OR ''1''=''1');
SQL

block injected
session shop <<'SQL'
SELECT id, name FROM customers WHERE email = 'x' OR '1'='1' LIMIT 3;
SQL

block injected-count
session shop <<'SQL'
SELECT count(*) FROM customers WHERE email = 'x' OR '1'='1';
SQL

# --- what-it-hides -------------------------------------------------------------------
block notes
session shop <<'SQL'
CREATE TABLE notes (id integer PRIMARY KEY, body text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
INSERT INTO notes (id, body) VALUES (1, 'from the database');
INSERT INTO notes (id, body, created_at) VALUES (2, 'from the application', NULL);
SQL

block notes-2
session shop <<'SQL'
INSERT INTO notes (id, body, created_at) VALUES (2, 'from the application', '2020-01-01');
SELECT id, body, created_at FROM notes ORDER BY id;
SQL

# --- migrations ----------------------------------------------------------------------
block concurrently
session shop <<'SQL'
BEGIN;
CREATE INDEX CONCURRENTLY ON orders (total);
SQL
