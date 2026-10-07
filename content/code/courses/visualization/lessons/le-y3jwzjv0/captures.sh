#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of visualization, as a script that
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

put grouped.py <<'PY'
import csv
import matplotlib.pyplot as plt

totals = {"2024": {}, "2025": {}}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        year, region = row["month"][:4], row["region"]
        totals[year][region] = totals[year].get(region, 0) + int(row["orders"])

regions = sorted(totals["2025"], key=totals["2025"].get, reverse=True)
for r in regions:
    before, after = totals["2024"][r], totals["2025"][r]
    print(f"{r:12} {before:7,} {after:7,}  {100 * (after / before - 1):+5.1f}%")

fig, ax = plt.subplots(figsize=(7, 3.5))
x = range(len(regions))
ax.bar([i - 0.2 for i in x], [totals["2024"][r] for r in regions], width=0.4, label="2024")
ax.bar([i + 0.2 for i in x], [totals["2025"][r] for r in regions], width=0.4, label="2025")
ax.set_xticks(list(x), regions)
ax.set_ylabel("orders")
ax.legend()
print("y axis from", ax.get_ylim()[0])
fig.savefig("grouped.png", dpi=150, bbox_inches="tight")
PY
block grouped
on '.venv/bin/python grouped.py'

put truncated.py <<'PY'
import matplotlib.pyplot as plt

northeast, south = 39924, 34926
floor = 34000

fig, ax = plt.subplots(figsize=(3, 3.5))
ax.bar(["Northeast", "South"], [northeast, south])
ax.set_ylim(floor, 41000)
fig.savefig("truncated.png", dpi=150, bbox_inches="tight")

in_data = northeast / south
on_page = (northeast - floor) / (south - floor)
print(f"in the data: {in_data:.2f} times")
print(f"on the page: {on_page:.2f} times")
print(f"lie factor:  {(on_page - 1) / (in_data - 1):.1f}")
PY
block truncated
on '.venv/bin/python truncated.py'
