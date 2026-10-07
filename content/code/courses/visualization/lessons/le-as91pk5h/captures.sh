#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of visualization, as a script that
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

put highlight.py <<'PY'
import csv
import matplotlib.pyplot as plt

totals = {"2024": {}, "2025": {}}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        year, region = row["month"][:4], row["region"]
        totals[year][region] = totals[year].get(region, 0) + int(row["orders"])
growth = {r: 100 * (totals["2025"][r] / totals["2024"][r] - 1) for r in totals["2025"]}

regions = sorted(growth, key=growth.get)
story = max(growth, key=growth.get)
colours = ["#d40f28" if r == story else "#c8ccd4" for r in regions]
print("highlighted:", story, f"{growth[story]:.1f}%")
print("in grey:    ", ", ".join(f"{r} {growth[r]:.1f}%" for r in regions if r != story))

fig, ax = plt.subplots(figsize=(6, 3))
ax.barh(regions, [growth[r] for r in regions], color=colours)
ax.set_title(f"{story} grew fastest", loc="left")
ax.set_xlabel("growth in orders, 2024 to 2025 (%)")
fig.savefig("highlight.png", dpi=150, bbox_inches="tight")
PY
block highlight
on '.venv/bin/python highlight.py'
