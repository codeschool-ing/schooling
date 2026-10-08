#!/usr/bin/env bash
# The psql sessions quoted in lesson 3 of sql-databases, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up && sudo bash ../../lab.sh role   # once
#   sudo bash captures.sh
#
# Runs in the database `shop` with lesson 1's ~/.psqlrc. Nothing here reads the
# shop's tables; `payments` is made and dropped by the session itself.
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
lab exec 'createdb shop'
python3 ../../lab/fence.py ../le-96rkt034/installing-postgresql.md 'cat > ~/.psqlrc' | lab exec bash

block float
session shop <<'SQL'
SELECT 0.1::double precision + 0.2::double precision = 0.3::double precision;
SQL

block divide
session shop <<'SQL'
SELECT 7 / 2;
SQL

block timestamptz
session shop <<'SQL'
CREATE TABLE payments (paid_at timestamptz NOT NULL);
SET TIME ZONE 'Europe/Lisbon';
INSERT INTO payments (paid_at) VALUES ('2026-10-24 01:30:00');
SET TIME ZONE 'UTC';
SELECT paid_at FROM payments;
SQL

block ambiguous
session shop <<'SQL'
SET TIME ZONE 'Europe/Lisbon';
INSERT INTO payments (paid_at) VALUES ('2026-10-25 01:30:00');
SET TIME ZONE 'UTC';
SELECT paid_at FROM payments ORDER BY paid_at;
SQL
