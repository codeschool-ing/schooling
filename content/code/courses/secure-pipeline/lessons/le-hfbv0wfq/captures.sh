#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: nothing of the project. The lesson works in ~/metrics, which
# this script empties first, and both programs are copied out of the lesson's
# own fences (`place`), so what runs here is what the student saves. The data
# set is generated with a fixed seed and a fixed "today" (2026-10-01), so
# every number is the same on every run and on the student's machine.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-hfbv0wfq
bash "$COURSE/lab.sh" as rm -rf metrics

block setup
run 'mkdir ~/metrics && cd ~/metrics'
run 'python3 --version'
place "$MD/the-data.md" "~/metrics/gen.py"
place "$MD/time-to-fix.md" "~/metrics/measure.py"

block gen
run 'python3 gen.py'
run 'sha256sum findings.csv inventory.csv'
run 'python3 gen.py'
run 'sha256sum findings.csv inventory.csv'

block head
run 'head -n 6 findings.csv'
run 'wc -l findings.csv inventory.csv'

block resolutions
run 'cut -d, -f9 findings.csv | sort | uniq -c'

block ttr
run 'python3 measure.py ttr'

block ttr-any
run 'python3 measure.py ttr-any'

block debt
run 'python3 measure.py debt'

block coverage
run 'python3 measure.py coverage'
run 'cut -d, -f2,3 findings.csv | sort | uniq -c | sort -rn'

block trend
run 'python3 measure.py trend'

block teams
run 'python3 measure.py teams'

block end
bash "$COURSE/lab.sh" as rm -rf metrics
exit 0
