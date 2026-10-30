#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of gcp-data (partitioning and
# clustering), as a script that produces them. Every transcript in the lesson
# was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# BIGQUERY IS NOT RUN: it has no emulator. DuckDB 1.5.6 reads the same orders
# as Hive-partitioned Parquet, and its plans, its file counts, its row-group
# statistics and its timings are measured. What BigQuery would bill is
# computed from them by the lesson's programs, read out of the .md files.
#
# STAGED: lesson 13's data set, rebuilt first with lesson 13's own
# make_orders.py and ask.py, out of sight, and lesson 14's ondemand.py.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-2dx6v6yt"
L13="$LESSONS/le-bz7j5spr"
L14="$LESSONS/le-z2k82dxr"

example "$L13/the-orders.md" make_orders.py make_orders.py || exit 1
file_fence "$L13/the-orders.md" ask.py > ask.py || exit 1
file_fence "$L14/on-demand.md" ondemand.py > ondemand.py || exit 1
python3 make_orders.py > /dev/null || exit 1

block plan
run "python3 ask.py \"EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt = DATE '2026-09-29'\""
block filters
run "python3 ask.py \"EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-07'\" | grep 'Scanning Files' || echo 'every file'"
run "python3 ask.py \"EXPLAIN SELECT sum(total_cents) FROM orders WHERE created_at >= TIMESTAMP '2026-09-29 00:00:00-03'\" | grep 'Scanning Files' || echo 'every file'"
run "python3 ask.py \"EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt + INTERVAL 1 DAY = DATE '2026-09-30'\" | grep 'Scanning Files' || echo 'every file'"
run "python3 ask.py \"EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt = (SELECT max(dt) FROM orders)\" | grep 'Scanning Files' || echo 'every file'"
run "python3 ask.py \"EXPLAIN SELECT sum(total_cents) FROM orders WHERE strftime(dt, '%Y-%m') = '2026-09'\" | grep 'Scanning Files' || echo 'every file'"
block week-bytes
run "python3 ask.py \"SELECT 16 * count(*) AS whole_table, 16 * count(*) FILTER (WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-07') AS one_week FROM orders\""
run 'python3 ondemand.py 19921888000; python3 ondemand.py 2339968000'

file_fence "$L/small-partitions.md" relayout.py > relayout.py || exit 1
block relayout
run 'time python3 relayout.py'
run 'for t in orders orders_by_hour orders_by_time orders_by_store; do echo "$t $(find warehouse/$t -name "*.parquet" | wc -l) files, $(du -sb warehouse/$t | cut -f1) bytes"; done'
block hours
run "python3 ask.py \"EXPLAIN ANALYZE SELECT district, sum(total_cents) FROM orders GROUP BY district\" | grep 'Total Time'"
run "python3 ask.py \"EXPLAIN ANALYZE SELECT district, sum(total_cents) FROM orders_by_hour GROUP BY district\" | grep 'Total Time'"

block groups
run "python3 ask.py \"SELECT row_group_id, stats_min_value AS min_store, stats_max_value AS max_store FROM parquet_metadata('warehouse/orders_by_store/dt=2026-09-29/*.parquet') WHERE path_in_schema = 'store_id' ORDER BY row_group_id\""
run "python3 ask.py \"SELECT CASE WHEN file_name LIKE '%by_store%' THEN 'by store' ELSE 'by time' END AS layout, count(*) AS row_groups, count(*) FILTER (WHERE stats_min_value::INT <= 7 AND stats_max_value::INT >= 7) AS may_hold_store_7 FROM parquet_metadata(['warehouse/orders_by_time/dt=2026-09-29/data_0.parquet', 'warehouse/orders_by_store/dt=2026-09-29/data_0.parquet']) WHERE path_in_schema = 'store_id' GROUP BY layout ORDER BY layout\""

run "python3 ask.py \"SELECT row_group_id, stats_min_value AS min_store, stats_max_value AS max_store FROM parquet_metadata('warehouse/orders_by_time/dt=2026-09-29/*.parquet') WHERE path_in_schema = 'store_id' ORDER BY row_group_id\""

example "$L/the-bill.md" layout_bill.py layout_bill.py || exit 1
block bill
run 'python3 layout_bill.py 1'
run 'python3 layout_bill.py 1000'
