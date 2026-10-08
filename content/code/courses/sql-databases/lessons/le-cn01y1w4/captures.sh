#!/usr/bin/env bash
# The psql sessions quoted in lesson 5 of sql-databases, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up && sudo bash ../../lab.sh role   # once
#   sudo bash captures.sh
#
# joins.sql is taken out of pairing-rows.md and loaded into a database of its
# own, `joins`, as the lesson tells the student to; each query is typed line by
# line, so the continuation prompt is psql's.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
lab() { bash "$LAB_SH" "$@"; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/sql-capture.lock; flock 9

lab role
lab exec 'dropdb --if-exists joins; createdb joins'
python3 ../../lab/fence.py ../le-96rkt034/installing-postgresql.md 'cat > ~/.psqlrc' | lab exec bash
python3 ../../lab/fence.py pairing-rows.md '-- joins.sql:' | lab exec 'cat > joins.sql'
lab exec 'psql -q joins -f joins.sql'

block inner
session joins <<'SQL'
SELECT c.name, o.id, o.total
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
SQL

block left
session joins <<'SQL'
SELECT c.name, o.id, o.total
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id;
SQL

block full
session joins <<'SQL'
SELECT c.name, o.id
FROM   customers c
FULL JOIN orders o ON o.customer_id = c.id;
SQL
