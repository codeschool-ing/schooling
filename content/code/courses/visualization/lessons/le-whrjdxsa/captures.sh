#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of visualization, as a script that
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

put pie.py <<'PY'
import csv
import matplotlib.pyplot as plt

with open("categories.csv") as f:
    rows = sorted(csv.DictReader(f), key=lambda r: int(r["revenue"]), reverse=True)
names = [r["category"] for r in rows]
revenue = [int(r["revenue"]) for r in rows]

total = sum(revenue)
for name, value in zip(names, revenue):
    print(f"{name:11} {value:4}  {100 * value / total:5.1f}%")

fig, (left, right) = plt.subplots(1, 2, figsize=(9, 3.5))
left.pie(revenue, labels=names, startangle=90, counterclock=False)
right.barh(names[::-1], revenue[::-1])
right.set_xlabel("revenue in 2025 (R$ thousands)")
fig.savefig("pie.png", dpi=150, bbox_inches="tight")
print("saved pie.png")
PY
block pie
on '.venv/bin/python pie.py'

block stevens
on '.venv/bin/python -c "print(round(6.5 ** 0.7, 2), round(10 ** 0.7, 2), round(2 ** 0.7, 2))"'
