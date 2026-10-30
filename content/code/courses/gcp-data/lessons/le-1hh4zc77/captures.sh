#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of gcp-data (Dataplex), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# NOTHING OF DATAPLEX RUNS HERE. There is no emulator for Dataplex, its catalog,
# the Data Lineage API or BigQuery's policy tags, and no emulator is started.
# What runs is two models the lesson labels as models: scan.py computes a data
# profile and four data quality rules with DuckDB, and emit.py and edges.py
# write OpenLineage run events to files and walk the graph they make. Both are
# read out of the lesson's schooling-example blocks; orders.csv is the fence
# quality.md introduces. The rest is arithmetic on the prices of the Dataplex
# pricing page, read 2026-10-30.
#
# STAGED: nothing beyond what lab.sh stages for every lesson.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$HERE"

# ---- catalog -------------------------------------------------------------------
block cat-price
run "python3 -c 'gib = 0.002739726 * 730; print(round(gib, 4), round(300 * 1024 / 2**30 * gib, 6))'"

# ---- quality -------------------------------------------------------------------
file_fence "$L/quality.md" orders.csv > orders.csv || exit 1
example "$L/quality.md" scan.py scan.py || exit 1
block dq-profile
run 'python3 scan.py profile orders.csv'
block dq-quality
run 'python3 scan.py quality orders.csv'
block dq-price
run "python3 -c 'print(round(0.5 * 30 * 0.141282, 2))'"

# ---- lineage -------------------------------------------------------------------
example "$L/lineage.md" emit.py emit.py || exit 1
example "$L/lineage.md" edges.py edges.py || exit 1
block lin-emit
run 'python3 emit.py 2026-10-01'
run 'cat events/2026-10-01-2-daily_revenue.json'
block lin-edges
run 'python3 edges.py'
run 'python3 edges.py upstream gs://quitanda-curated-prod/finance/revenue/dt=2026-10-01/revenue.csv'
run 'python3 edges.py downstream bigquery/planner-dev.curated.customers'
block end
