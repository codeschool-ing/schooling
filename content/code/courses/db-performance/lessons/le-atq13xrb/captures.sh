#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset). events_by_month.sql is taken
# out of this lesson's own range.md, so the file shown is the file that ran;
# lesson 18's captures take it from the same place.
#
# Nothing is staged. The lesson ends, as the student's does, with
# ~/reset-market.sh and the file run once more, which is where lesson 18
# starts.
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
python3 "$FENCE" range.md '-- events_by_month.sql' | lab as 'cat > ~/events_by_month.sql'

# ---------------------------------------------------------------- why partition
block delete
session market <<'S'
BEGIN;
SELECT pg_current_wal_lsn() AS before \gset
DELETE FROM events WHERE at < '2025-11-01';
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal_written;
ROLLBACK;
S

# ---------------------------------------------------------------- range
block build
on 'psql market -v ON_ERROR_STOP=1 -f events_by_month.sql'
block describe
session market <<'S'
\d+ events_by_month
SELECT tableoid::regclass AS partition, count(*), pg_size_pretty(pg_relation_size(tableoid)) AS size FROM events_by_month GROUP BY 1 ORDER BY 1;
S
block no-partition
session market <<'S'
INSERT INTO events_by_month VALUES (0, '2026-03-01', NULL, 'view', '{}');
S
block not-faster
session market <<'S'
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM events WHERE id = 2500000;
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM events_by_month WHERE id = 2500000;
S

# ---------------------------------------------------------------- list and hash
block list
session market <<'S'
CREATE TABLE events_by_kind (LIKE events_by_month) PARTITION BY LIST (kind);
CREATE TABLE events_browse PARTITION OF events_by_kind FOR VALUES IN ('view', 'search');
CREATE TABLE events_buy PARTITION OF events_by_kind FOR VALUES IN ('cart', 'checkout');
INSERT INTO events_by_kind SELECT * FROM events;
SELECT tableoid::regclass AS partition, kind, count(*) FROM events_by_kind GROUP BY 1, 2 ORDER BY 1, 2;
S
block hash
session market <<'S'
CREATE TABLE events_by_customer (LIKE events_by_month) PARTITION BY HASH (customer_id);
CREATE TABLE events_by_customer_0 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE events_by_customer_1 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE events_by_customer_2 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE events_by_customer_3 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 3);
INSERT INTO events_by_customer SELECT * FROM events;
SELECT tableoid::regclass AS partition, count(*), count(customer_id) AS with_customer FROM events_by_customer GROUP BY 1 ORDER BY 1;
S
block drop-two
session market <<'S'
DROP TABLE events_by_kind, events_by_customer;
S

# ---------------------------------------------------------------- attach / detach
block attach
session market <<'S'
CREATE TABLE events_2026_02 (LIKE events_by_month INCLUDING DEFAULTS);
ALTER TABLE events_2026_02 ADD CHECK (at >= '2026-02-01' AND at < '2026-03-01');
ALTER TABLE events_by_month ATTACH PARTITION events_2026_02 FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
S
block drop-month
session market <<'S'
SELECT pg_current_wal_lsn() AS before \gset
ALTER TABLE events_by_month DETACH PARTITION events_2025_10;
DROP TABLE events_2025_10;
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal_written;
S
block concurrently
session market <<'S'
ALTER TABLE events_by_month DETACH PARTITION events_2026_02 CONCURRENTLY;
CREATE TABLE events_default PARTITION OF events_by_month DEFAULT;
ALTER TABLE events_by_month DETACH PARTITION events_2026_01 CONCURRENTLY;
INSERT INTO events_by_month VALUES (0, '2026-03-01', NULL, 'view', '{}');
SELECT tableoid::regclass, id, at FROM events_by_month WHERE id = 0;
S

# ---------------------------------------------------------------- keys and indexes
block pk
session market <<'S'
CREATE TABLE events_wrong (id bigint PRIMARY KEY, at timestamptz NOT NULL) PARTITION BY RANGE (at);
S
block indexes
session market <<'S'
\di events_2025_1*
CREATE INDEX CONCURRENTLY ON events_by_month (kind);
S

# ---------------------------------------------------------------- back to lesson 18's start
block reset
on '~/reset-market.sh'
on 'psql -q market -v ON_ERROR_STOP=1 -f events_by_month.sql'
