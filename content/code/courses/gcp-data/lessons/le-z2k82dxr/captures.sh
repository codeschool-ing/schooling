#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of gcp-data (on demand and slots),
# as a script that produces them. Every transcript in the lesson was copied
# from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# NOTHING IN THIS LESSON TALKS TO BIGQUERY: there is no emulator for it, and
# reservations, commitments and quotas have no control plane here. What runs
# is arithmetic: three programs read out of the lesson's .md files, which apply
# the pricing page's prices and rules (read 2026-10-30) to numbers the lesson
# states. The byte counts come from lesson 13's table, and the data set is
# rebuilt first with lesson 13's own make_orders.py and ask.py, out of sight,
# so the one query here that reads it has something to read.
#
# STAGED: lesson 13's data set, rebuilt as above.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-z2k82dxr"
L13="$LESSONS/le-bz7j5spr"

example "$L13/the-orders.md" make_orders.py make_orders.py || exit 1
file_fence "$L13/the-orders.md" ask.py > ask.py || exit 1
python3 make_orders.py > /dev/null || exit 1

file_fence "$L/on-demand.md" ondemand.py > ondemand.py || exit 1
block bytes
run 'python3 ask.py "SELECT 8 * count(*) AS total_cents_bytes, 8 * count(*) FILTER (WHERE dt = DATE '"'"'2026-09-29'"'"') AS one_day FROM orders"'
block ondemand
run 'python3 ondemand.py 9960944'
run 'python3 ondemand.py 130872'
run 'python3 ondemand.py 99177572'
run 'python3 ondemand.py 19921888 400'
run 'python3 ondemand.py 2199023255552'
block month
run "python3 -c 'print(24 * 30 * 22.5, (24 * 30 * 2**41 / 2**40 - 1) * 11.25)'"

block editions
run "python3 -c 'print(100 * 730 * 0.062, 100 * 730 * 0.093, 100 * 730 * 0.155)'"

file_fence "$L/autoscaling.md" autoscale.py > autoscale.py || exit 1
block autoscale
run 'python3 autoscale.py 4 3 100000'
run 'python3 autoscale.py 4 3 100000 fluid'
run 'python3 autoscale.py 400 120 300'
run 'python3 -c "print(100000 * 10 * 2**20 / 2**40)"'

example "$L/break-even.md" breakeven.py breakeven.py || exit 1
block breakeven
run 'python3 breakeven.py 3 600'
run 'python3 breakeven.py 40 2500'
