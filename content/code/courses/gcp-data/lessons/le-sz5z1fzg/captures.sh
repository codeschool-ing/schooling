#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of gcp-data (the query plan and the
# bytes scanned), as a script that produces them. Every transcript in the
# lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# BIGQUERY IS NOT RUN: no dry run, no maximum bytes billed and no execution
# graph exists here, and the lesson shows those as commands nobody ran. What
# runs is DuckDB 1.5.6 over lesson 13's Parquet files: bqbill.py (read out of
# bytes-billed.md) computing what BigQuery would bill from the documented type
# sizes, DuckDB's own EXPLAIN ANALYZE, and the Parquet footers.
#
# STAGED: lesson 13's data set, rebuilt first with lesson 13's own
# make_orders.py and ask.py, out of sight.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-sz5z1fzg"
L13="$LESSONS/le-bz7j5spr"

example "$L13/the-orders.md" make_orders.py make_orders.py || exit 1
file_fence "$L13/the-orders.md" ask.py > ask.py || exit 1
python3 make_orders.py > /dev/null || exit 1

example "$L/bytes-billed.md" bqbill.py bqbill.py || exit 1
block bill
run 'python3 bqbill.py orders dt,store_id,total_cents 2026-09-29 2026-09-29'
run 'python3 bqbill.py orders dt,district,total_cents 2026-09-01 2026-09-29'
run 'python3 bqbill.py orders order_id,customer_id,store_id,district,items,total_cents,payment,created_at,dt'

block plan
run "python3 ask.py \"EXPLAIN ANALYZE SELECT district, sum(total_cents) AS sales FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-29' GROUP BY district ORDER BY sales DESC\""

block physical
run "python3 ask.py \"SELECT path_in_schema AS column_name, sum(total_compressed_size) AS on_disk, sum(total_uncompressed_size) AS uncompressed FROM parquet_metadata('warehouse/orders/dt=2026-09-*/*.parquet') WHERE path_in_schema IN ('district', 'total_cents') GROUP BY ALL ORDER BY column_name\""
run "python3 ask.py \"SELECT path_in_schema AS column_name, encodings, compression FROM parquet_metadata('warehouse/orders/dt=2026-09-29/*.parquet') WHERE path_in_schema IN ('district', 'total_cents')\""
