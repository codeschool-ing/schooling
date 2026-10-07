#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of visualization, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ana's account and ~/viz holding
# horta.py, which the lesson has the student save from the page. Everything
# after that is typed as the lesson shows it, starting from no virtual
# environment at all. pip downloads matplotlib from the Python Package Index,
# so this needs the network once.
#
# Recorded on Ubuntu 24.04, Python 3.13, matplotlib 3.11.2, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~/viz$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab up >/dev/null
lab exec 'find . -mindepth 1 -maxdepth 1 ! -name horta.py -exec rm -rf {} +'

block setup
on 'python3 --version'
on 'python3 -m venv .venv'
on '.venv/bin/pip install --quiet matplotlib==3.11.2'
on '.venv/bin/python -c "import matplotlib; print(matplotlib.__version__)"'

block data
on '.venv/bin/python horta.py'
on 'head -4 monthly.csv'

put bars.py <<'PY'
import csv
import matplotlib.pyplot as plt

totals = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        if row["month"].startswith("2025"):
            region = row["region"]
            totals[region] = totals.get(region, 0) + int(row["orders"])

regions = sorted(totals, key=totals.get)
values = [totals[r] for r in regions]
for region, value in zip(regions, values):
    print(f"{region:12} {value:7,}")

fig, ax = plt.subplots(figsize=(6, 3))
ax.barh(regions, values, color="#2b52c9")
ax.set_xlabel("orders in 2025")
fig.savefig("bars.png", dpi=150, bbox_inches="tight")
print("saved bars.png")
PY
block first-chart
on '.venv/bin/python bars.py'
on 'file bars.png'

block failures
on 'python3 bars.py'
on '.venv/bin/python bar.py'
