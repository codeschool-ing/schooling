#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of visualization, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh ready     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the virtual environment and the CSV
# files lesson 1 has the student make, rebuilt here by `lab.sh reset`.
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


lab reset >/dev/null

put index.py <<'PY'
import csv
import matplotlib.pyplot as plt

series = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        series.setdefault(row["region"], []).append(int(row["orders"]))

indexed = {r: [100 * v / values[0] for v in values] for r, values in series.items()}
for r in sorted(indexed, key=lambda r: indexed[r][-1], reverse=True):
    print(f"{r:12} {series[r][0]:5} -> {series[r][-1]:5}   index {indexed[r][-1]:5.1f}")

fig, ax = plt.subplots(figsize=(7, 3.5))
for r, values in indexed.items():
    ax.plot(values, label=r)
ax.axhline(100, color="grey", linewidth=0.8, linestyle="--")
ax.set_ylabel("January 2024 = 100")
ax.legend()
fig.savefig("indexed.png", dpi=150, bbox_inches="tight")
PY
block index
on '.venv/bin/python index.py'

put dual.py <<'PY'
import csv
import matplotlib.pyplot as plt

series = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        series.setdefault(row["region"], []).append(int(row["orders"]))

fig, left = plt.subplots(figsize=(7, 3.5))
right = left.twinx()
left.plot(series["Southeast"], color="#2b52c9")
right.plot(series["North"], color="#d40f28", linestyle="--")
print("left axis: ", [round(v) for v in left.get_ylim()])
print("right axis:", [round(v) for v in right.get_ylim()])
fig.savefig("dual.png", dpi=150, bbox_inches="tight")
PY
block dual
on '.venv/bin/python dual.py'
