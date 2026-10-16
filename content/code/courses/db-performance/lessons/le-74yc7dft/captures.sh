#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset). dashboard.py is put together
# from the parts of the annotated example in cache-aside.md, joined the way the
# page's copy button joins them; race.py and stampede.py are taken out of
# invalidation.md and stampede.md. All three run as they are printed.
#
# STAGED: redis-server, python3-redis and python3-psycopg are installed when
# the machine is built, and redis-server is disabled there, so this script
# starts it; on the student's machine `apt install` starts it. The race in
# invalidation is interleaved by race.py itself, in one process, which the
# lesson says: the order is forced, the effect is real.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
lab root 'systemctl start redis-server; redis-cli flushall >/dev/null'
python3 "$FENCE" cache-aside.md '{"language": "python", "file": "dashboard.py"' \
  | python3 -c 'import json,sys; print("\n".join(p["code"] for p in json.load(sys.stdin)["parts"]))' \
  | lab as 'cat > dashboard.py'
python3 "$FENCE" invalidation.md '# race.py:' | lab as 'cat > race.py'
python3 "$FENCE" stampede.md '# stampede.py:' | lab as 'cat > stampede.py'

block ping
on 'systemctl is-active redis-server'
on 'redis-cli ping'

block bench
on 'python3 dashboard.py'

block ttl
on 'redis-cli DEL dashboard:7'
on 'python3 dashboard.py 7'
on "psql market -c \"INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (42, 7, now(), 'pending', 1990)\""
on 'python3 dashboard.py 7'
on 'redis-cli TTL dashboard:7'
on "psql market -c \"SELECT count(*) FROM orders WHERE seller_id = 7 AND placed_at >= '2025-12-01'\""
sleep 60
on 'python3 dashboard.py 7'

block race
on 'python3 race.py'
on 'python3 race.py guarded'

block stampede
on "psql -q market -c 'SELECT pg_stat_statements_reset()' > /dev/null"
on 'python3 stampede.py'
on "psql market -c \"SELECT calls, round(mean_exec_time) AS mean_ms FROM pg_stat_statements WHERE query LIKE '%FROM orders WHERE status%'\""
on "psql -q market -c 'SELECT pg_stat_statements_reset()' > /dev/null"
on 'python3 stampede.py single-flight'
on "psql market -c \"SELECT calls, round(mean_exec_time) AS mean_ms FROM pg_stat_statements WHERE query LIKE '%FROM orders WHERE status%'\""

block matview
cat <<'SQL' | session market
SELECT sum(count) FROM (SELECT count(*) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY date_trunc('day', placed_at)) AS d;
CREATE MATERIALIZED VIEW seller_days AS SELECT seller_id, date_trunc('day', placed_at)::date AS day, count(*) AS orders, sum(total_cents)::bigint AS total FROM orders WHERE placed_at >= '2025-12-01' GROUP BY 1, 2;
REFRESH MATERIALIZED VIEW CONCURRENTLY seller_days;
CREATE UNIQUE INDEX ON seller_days (seller_id, day);
SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (42, 42, now(), 'pending', 1990);
SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
REFRESH MATERIALIZED VIEW CONCURRENTLY seller_days;
SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
REFRESH MATERIALIZED VIEW seller_days;
SQL

block stop
on 'sudo systemctl stop redis-server'
lab reset
