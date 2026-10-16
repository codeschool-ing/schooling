#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. lake.py, ask.py and footer.py are read out of
# lesson 15, where they are shown; layouts.py out of this lesson.
#
# ATHENA IS NOT RUN. Every byte count is what ask.py measured DuckDB reading
# from moto's S3, and every price is the sheet's line times that count. The
# files are real Parquet, ORC and gzipped CSV written by PyArrow, and their
# sizes and footers are what PyArrow wrote.
#
# STAGED: nothing beyond lesson 1's lab and the programs of lesson 15, which
# the student saved there. layouts.py writes 3,162 objects and takes the
# longest of any command in the course.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
example "$LESSONS/le-2vfrcj3x/the-lake.md" lake.py lake.py || exit 1
example "$LESSONS/le-2vfrcj3x/asking.md" ask.py ask.py || exit 1
file_fence "$LESSONS/le-2vfrcj3x/three-reads.md" footer.py > footer.py || exit 1
example "$HERE/rows-and-columns.md" layouts.py layouts.py || exit 1
Q='SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC'
T='quitanda-curated-prod/layouts'

block setup
run 'aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod'
run 'python3 lake.py'

block layouts
run 'python3 layouts.py'

block codec-gzip
run "python3 ask.py -t t=$T/csv-gzip/:csv \"$Q\""
block codec-none
run "python3 ask.py -t t=$T/parquet-none/:parquet \"$Q\" | tail -2"
block codec-snappy
run "python3 ask.py -t t=quitanda-curated-prod/orders/:parquet \"$Q\" | tail -2"
block codec-zstd
run "python3 ask.py -t t=$T/parquet-zstd/:parquet \"$Q\" | tail -2"
block codec-orc
run "python3 ask.py -t t=$T/orc-zstd/:orc \"$Q\" | tail -2"

block groups-footer
run "python3 footer.py s3://$T/groups/dt=2026-10-15/orders.parquet | grep -E 'rows|hour'"
block shuffled-footer
run "python3 footer.py s3://$T/groups-shuffled/dt=2026-10-15/orders.parquet | grep -E 'rows|hour'"
block groups-ask
run "python3 ask.py \"SELECT sum(total_cents) / 100 AS late FROM orders WHERE hour >= 21\" | tail -2"
run "python3 ask.py -t t=$T/groups/:parquet \"SELECT sum(total_cents) / 100 AS late FROM t WHERE hour >= 21\""
run "python3 ask.py -t t=$T/groups-shuffled/:parquet \"SELECT sum(total_cents) / 100 AS late FROM t WHERE hour >= 21\" | tail -2"

block cardinality
run 'python3 ask.py "SELECT count(DISTINCT dt) AS days, count(DISTINCT neighbourhood) AS neighbourhoods, count(DISTINCT customer_id) AS customers FROM orders"'

block small-month
run "python3 ask.py -t t=$T/small-files/:parquet \"$Q\" | tail -2"
block small-day
run "python3 ask.py -t t=$T/small-files/:parquet \"SELECT count(*) AS orders FROM t WHERE dt = '2026-10-15' AND payment = 'pix'\" | tail -2"
run "python3 ask.py \"SELECT count(*) AS orders FROM orders WHERE dt = '2026-10-15' AND payment = 'pix'\""

block prices
run "python3 prices.py s3 | grep -E 'GET and|PUT'"
run 'python3 prices.py athena | tail -1'
