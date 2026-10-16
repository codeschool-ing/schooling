#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 18 starts: lab.sh reset (lesson 3's start) and then
# events_by_month.sql, taken out of lesson 17's range.md, which is how lesson
# 17 ends. events_by_day.sql is taken out of this lesson's own too-many.md, so
# the files shown are the files that ran.
#
# STAGED: plans with 365 partitions run to hundreds of lines, so the lesson
# shows those through `psql -c … | grep`, printed as the command the student
# types; nothing else is cut.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
L17=../le-atq13xrb
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
python3 "$FENCE" "$L17/range.md" '-- events_by_month.sql' | lab as 'cat > ~/events_by_month.sql'
lab as 'psql -q market -v ON_ERROR_STOP=1 -f events_by_month.sql' >/dev/null 2>&1
python3 "$FENCE" too-many.md '-- events_by_day.sql' | lab as 'cat > ~/events_by_day.sql'

DAY="at >= '2025-11-10' AND at < '2025-11-11'"
# ---------------------------------------------------------------- plan time
block start
printf "\\\\d events_by_month\n" | session market
block pruned
printf "EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE $DAY;\n" | session market
block all
printf "EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month;\nEXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= '2025-12-20';\n" | session market
block versus
printf "EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events WHERE $DAY;\nEXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE $DAY;\n" | session market

# ---------------------------------------------------------------- run time
block prepared
session market <<'S'
PREPARE day_count(timestamptz) AS SELECT count(*) FROM events_by_month WHERE at >= $1 AND at < $1 + interval '1 day';
SET plan_cache_mode = force_generic_plan;
EXPLAIN (ANALYZE, COSTS OFF) EXECUTE day_count('2025-11-10');
S
block subquery
session market <<'S'
EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE at >= (SELECT max(placed_at) FROM orders) - interval '1 day';
S

# ---------------------------------------------------------------- ignored
block function
session market <<'S'
EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM events_by_month WHERE date(at) = '2025-11-10';
S
block other-column
session market <<'S'
EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE customer_id = 42;
EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month WHERE extract(month FROM at) = 11;
S

# ---------------------------------------------------------------- too many
block build-day
on 'psql market -v ON_ERROR_STOP=1 -f events_by_day.sql'
block plan-month
on "psql market -c \"EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_month WHERE customer_id = 42\" | grep -E 'Append|Planning|Execution'"
on "psql market -c \"EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_month WHERE customer_id = 42\" | grep -E 'Append|Planning|Execution'"
block plan-day
on "psql market -c \"EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE customer_id = 42\" | grep -E 'Append|Planning|Execution'"
on "psql market -c \"EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE customer_id = 42\" | grep -E 'Append|Planning|Execution'"
block plan-day-pruned
on "psql market -c \"EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE $DAY\" | grep -E 'Scan|Planning|Execution'"

# ---------------------------------------------------------------- partitionwise
block pw-agg
session market <<'S'
SHOW enable_partitionwise_aggregate;
SELECT kind, count(*) FROM events_by_month GROUP BY kind;
SET enable_partitionwise_aggregate = on;
EXPLAIN (COSTS OFF) SELECT kind, count(*) FROM events_by_month GROUP BY kind;
SELECT kind, count(*) FROM events_by_month GROUP BY kind;
S
block pw-join
session market <<'S'
SET enable_partitionwise_join = on;
EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month AS a JOIN events_by_month AS b USING (id, at);
S

block pw-mixed
on "psql market -c 'SET enable_partitionwise_join = on' -c 'EXPLAIN (COSTS OFF) SELECT count(*) FROM events_by_month AS a JOIN events_by_day AS b USING (id, at)' | grep -E 'Join|Append'"

block reset
on '~/reset-market.sh'
