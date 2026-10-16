#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l06.txt
#
# Needs the machine lesson 1 builds, with the cluster running, and the silver
# layer lesson 5's to_parquet.py wrote. Every program is taken out of the
# lesson's .md by `lab.sh extract`.
#
# formatted.py prints its plan, its result and its final plan in one run; the
# lesson quotes the first part in section 04 and the rest in section 10, so the
# one output is cut in two at the line its `print` writes.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab start >/dev/null 2>&1
put four-plans.md plans.py
put reading-a-physical-plan.md formatted.py
put measuring-a-scan.md lastscan.py
put measuring-a-scan.md pruning.py
put column-pruning.md scan_plans.py
put choosing-a-join.md joins_chosen.py

block plans
on 'spark-submit plans.py'
on 'spark-submit formatted.py' > /tmp/formatted.out
block formatted
sed -n '1,/^\[Row(/{/^\[Row(/!p}' /tmp/formatted.out
block final-plan
sed -n '/^\[Row(/,$p' /tmp/formatted.out
block pruning
on 'spark-submit pruning.py'
block scan-plans
on "spark-submit scan_plans.py 2>&1 | grep -E '^(---|PartitionFilters|PushedFilters|ReadSchema)'"
block joins
on 'spark-submit joins_chosen.py'
