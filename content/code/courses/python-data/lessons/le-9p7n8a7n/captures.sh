#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of python-data, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, by ../../lab/fill.py, and
# `fill.py --check` holds the lesson to it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l21.txt
#   python3 ../../lab/fill.py --check . /tmp/l21.txt
#
# What is STAGED rather than typed: stations.ipynb is made from
# the-notebook-as-a-script.md's own `py` fences by ../../lab/order.py, which runs
# them top to bottom in a kernel and saves the result, as JupyterLab does when
# Ana runs them and presses Ctrl+S. station_report.py is the schooling-example
# of functions-and-main.md, its parts joined; requirements.txt is lesson 3's
# file, from requirements.md. A student saves each of those from the page.
# README.md is written here as the student writes it in JupyterLab, from what
# what-goes-with-it.md says it holds.
#
# The output of `%time` is a timing and varies, so the notebook's cells are
# run but the block that would show it is not quoted.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf '(.venv) ana@lab:~/pydata$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# A command and then `echo $?`. Each `lab exec` is a new shell, so the command is run a
# second time, quietly, with the echo after it, and the status shown is that run's.
status() { printf '(.venv) ana@lab:~/pydata$ %s\n' "$*"; lab exec "$* 2>&1" || true
           printf '(.venv) ana@lab:~/pydata$ %s\n' 'echo $?'; lab exec "$* >/dev/null 2>&1; echo \$?"; }
lab reset >/dev/null

lab exec "python '$HERE/../../lab/order.py' '$HERE/the-notebook-as-a-script.md' stations.ipynb 0 1 2 3" >/dev/null 2>&1
lab exec "rm -f S05.png"

block convert
on jupyter nbconvert --to script stations.ipynb

block cat
on cat stations.py

block run
on python stations.py

# --- the script ---------------------------------------------------------------
lab exec "python - '$HERE/functions-and-main.md' > station_report.py <<'PY'
import json, re, sys
text = open(sys.argv[1], encoding='utf-8').read()
block = re.search(r'^\`\`\`schooling-example\n(.*?)^\`\`\`$', text, re.S | re.M).group(1)
sys.stdout.write(''.join(p['code'] for p in json.loads(block)['parts']))
PY"

block import
on "python -c 'from station_report import load, per_month; print(per_month(load(\"trips.csv\"), \"S12\").sum())'"
on ls S12.png

block help
on python station_report.py -h

block run-s05
on python station_report.py S05

block run-s12
on python station_report.py S12 --out quiet.png

block bad
status python station_report.py S99

block missing
status python station_report.py

# --- running elsewhere ----------------------------------------------------------
block elsewhere-bad
printf '(.venv) ana@lab:~/pydata$ %s\n' 'cd /tmp'
printf '(.venv) ana@lab:/tmp$ %s\n' 'python ~/pydata/station_report.py S05 --data trips.csv'
lab exec 'cd /tmp && python ~/pydata/station_report.py S05 --data trips.csv 2>&1' || true

block elsewhere-ok
printf '(.venv) ana@lab:/tmp$ %s\n' 'python ~/pydata/station_report.py S05'
lab exec 'cd /tmp && python ~/pydata/station_report.py S05 2>&1' || true
lab exec 'rm -f /tmp/S05.png'

# --- what goes with it ------------------------------------------------------------
lab exec "python - '$HERE/../le-qhfsx55s/requirements.md' > requirements.txt <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
sys.stdout.write(re.search(r'^\`\`\`\n(jupyterlab==.*?)^\`\`\`$', text, re.S | re.M).group(1))
PY"
lab exec "cat > README.md" <<'MD'
# Station report

Trips per month from one Maré Bikes station, as a table and a chart.

    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    python station_report.py S05

`--data` points at another trips file, `--out` names the chart, and
`python station_report.py -h` lists both.
MD

block requirements
on cat requirements.txt

# `ls` lays its names out in columns at a terminal and one per line into a
# pipe; -C asks for the columns a student sees.
block readme
on cat README.md

block project
printf '(.venv) ana@lab:~/pydata$ %s\n' 'ls'
lab exec 'COLUMNS=100 ls -C' 
