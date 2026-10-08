#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of visualization, as a script that
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

put liefactor.py <<'PY'
import csv
import matplotlib.pyplot as plt

totals = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        if row["region"] == "Southeast":
            year = row["month"][:4]
            totals[year] = totals.get(year, 0) + int(row["orders"])

a, b = totals["2024"], totals["2025"]
change = (b - a) / a
print(f"Southeast 2024: {a:,}   2025: {b:,}")
print(f"change in the data: {change:+.1%}")

for start in (0, 50_000, 65_000):
    drawn = (b - start) / (a - start) - 1
    print(f"axis from {start:>6,}: bars differ by {drawn:+7.1%}, lie factor {drawn / change:4.1f}")

fig, axes = plt.subplots(1, 2, figsize=(7, 3))
for ax, start in zip(axes, (0, 65_000)):
    ax.bar(["2024", "2025"], [a, b], color="#2b52c9")
    ax.set_ylim(start, 80_000)
    ax.set_title(f"axis from {start:,}", loc="left")
fig.savefig("liefactor.png", dpi=150, bbox_inches="tight")
PY
block liefactor
on '.venv/bin/python liefactor.py'
