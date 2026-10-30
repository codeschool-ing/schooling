#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal". No emulator is used: the Delta tables are folders on the local
# disk, written and read by the deltalake library, DuckDB and PyArrow.
# orders.py is read out of lesson 17, where it is shown; table.py, layouts.py
# and measure.py out of this lesson, so there is no second copy here.
#
# NO AZURE SERVICE IS RUN. The byte counts are what measure.py counted PyArrow
# reading from the local disk for DuckDB; the prices in the-bill.md are
# illustrative numbers multiplied by those counts, and say so.
#
# STAGED: nothing. The names of the Parquet files are random and change on
# every run; layouts.py makes 560 commits and is the slowest command here.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
file_fence "$LESSONS/le-f5tg0ejs/delta-in-a-container.md" orders.py > orders.py || exit 1
example "$HERE/the-log.md" table.py table.py || exit 1
file_fence "$HERE/partitions.md" layouts.py > layouts.py || exit 1
example "$HERE/partitions.md" measure.py measure.py || exit 1
MONTH="SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
DAY="SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'"

block log
run "python -c \"from deltalake import write_deltalake; from orders import october; write_deltalake('lake/flat', october())\""
run 'find lake/flat -type f | sort'
run 'python table.py lake/flat files'
run "python table.py lake/flat delete \"order_id = '1015-00042'\""
run 'python table.py lake/flat files'
run "jq -c 'if .add then {add: .add.path} elif .remove then {remove: .remove.path, dataChange: .remove.dataChange} else empty end' lake/flat/_delta_log/00000000000000000001.json"
run 'ls lake/flat/*.parquet | wc -l'
run 'python table.py lake/flat read'
run "python -c \"import duckdb; duckdb.sql(\\\"SELECT count(*) AS orders FROM 'lake/flat/*.parquet'\\\").show()\""

block layouts
run 'time python layouts.py'
run 'for t in one by_day daily hourly; do python table.py lake/$t files; done'
run 'ls lake/by_day | head -4'
run "python -c \"import glob, pyarrow.parquet as pq; print(pq.read_schema(glob.glob('lake/by_day/dt=2026-10-15/*.parquet')[0]).names)\""

block measure
run "python measure.py lake/one \"$MONTH\""
run "python measure.py lake/by_day \"$MONTH\" | tail -1"
run "python measure.py lake/one \"$DAY\""
run "python measure.py lake/by_day \"$DAY\" | tail -1"
run "python measure.py lake/daily \"$DAY\" | tail -1"
run "python table.py lake/by_day delete \"order_id = '1015-00042'\""

block small
run "python measure.py lake/hourly \"$MONTH\" | tail -1"
run "python measure.py lake/hourly \"$DAY\" | tail -1"
run 'python table.py lake/hourly compact'
run 'python table.py lake/hourly files'
run "python measure.py lake/hourly \"$MONTH\" | tail -1"
run "find lake/hourly -name '*.parquet' -not -path '*_delta_log*' | wc -l"
run "jq -r 'select(.add or .remove) | \"\\(keys[0]) dataChange=\\((.add // .remove).dataChange)\"' lake/hourly/_delta_log/00000000000000000527.json | sort | uniq -c"

block travel
run 'python table.py lake/hourly history | sed -n 1,3p'
run 'python table.py lake/hourly history | tail -2'
run 'ls lake/hourly/_delta_log | grep -v json'
run 'python table.py lake/hourly@100 files'
run 'python table.py lake/hourly@100 read'
run 'python table.py lake/hourly vacuum 0 2>&1 | tail -1'
run 'python table.py lake/hourly vacuum 0 force'
run 'python table.py lake/hourly@100 files'
run 'python table.py lake/hourly@100 read'
run 'python table.py lake/hourly read'
run 'python table.py lake/hourly history | tail -2'
