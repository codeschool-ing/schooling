#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of sql-databases, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up && sudo bash ../../lab.sh role   # once
#   sudo bash captures.sh
#
# shop-large.sql is taken out of the-large-shop.md and loaded as the lesson
# says to. Lessons 10 and 11 start from the database this leaves behind.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, 4 cores, TZ=UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/sql-capture.lock; flock 9

lab role >/dev/null 2>&1
lab exec 'createdb shop'
python3 ../../lab/fence.py ../le-96rkt034/installing-postgresql.md 'cat > ~/.psqlrc' | lab exec bash
python3 ../../lab/fence.py the-large-shop.md '-- shop-large.sql:' | lab exec 'cat > shop-large.sql'

block load
on 'dropdb shop'
on 'createdb shop'
on 'psql shop -f shop-large.sql'

block summary
on 'psql shop -c "SELECT status, count(*) FROM orders GROUP BY status ORDER BY count(*) DESC"'
on 'psql shop -c "SELECT count(*) AS order_lines FROM order_lines"'
on "psql shop -c \"SELECT pg_size_pretty(pg_database_size('shop')) AS size\""
