#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of gcp-data (materialised views,
# scheduled queries and BI Engine), as a script that produces them. Every
# transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# NO MATERIALISED VIEW, SCHEDULED QUERY OR BI ENGINE RESERVATION RUNS HERE:
# BigQuery has no emulator. What runs is the idea of an incremental aggregate,
# done by hand on DuckDB by incremental.py (read out of incremental.md), and
# labelled in the lesson as the idea and not BigQuery's implementation; plus
# lesson 16's bqbill.py on the aggregate, and arithmetic on the pricing page.
#
# STAGED: lesson 13's data set, rebuilt first with lesson 13's own
# make_orders.py and ask.py, and lesson 16's bqbill.py, out of sight.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-pa4v4t93"
L13="$LESSONS/le-bz7j5spr"
L16="$LESSONS/le-sz5z1fzg"

example "$L13/the-orders.md" make_orders.py make_orders.py || exit 1
file_fence "$L13/the-orders.md" ask.py > ask.py || exit 1
example "$L16/bytes-billed.md" bqbill.py bqbill.py || exit 1
python3 make_orders.py > /dev/null || exit 1

example "$L/incremental.md" incremental.py incremental.py || exit 1
block incremental
run 'mv warehouse/orders/dt=2026-09-29 day-60'
run 'python3 incremental.py'
run 'python3 incremental.py'
run 'mv day-60 warehouse/orders/dt=2026-09-29'
run 'python3 incremental.py'
block check
run 'python3 ask.py "SELECT count(*) AS differences FROM (SELECT dt, district, count(*) AS orders, sum(total_cents) AS sales FROM orders GROUP BY ALL EXCEPT SELECT dt, district, orders, sales FROM daily_sales)"'
run "python3 ask.py \"SELECT district, orders, sales FROM daily_sales WHERE dt = DATE '2026-09-29' ORDER BY district\""
block correction
run "rm -r 'warehouse/daily_sales/dt=2026-09-15' && python3 incremental.py"

block rewrite
run 'python3 bqbill.py orders dt,district,total_cents'
run 'python3 bqbill.py daily_sales dt,district,sales'

block bi
run "python3 -c 'print(round(2 * 0.0749 * 730, 2), round(2 * 54.677, 2))'"
