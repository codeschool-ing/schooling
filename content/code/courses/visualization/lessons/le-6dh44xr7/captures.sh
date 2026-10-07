#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of visualization, as a script that
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

put week.py <<'PY'
import csv
import matplotlib.pyplot as plt

days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
hours = list(range(8, 23))
grid = [[0] * len(hours) for _ in days]
with open("hourly.csv") as f:
    for row in csv.DictReader(f):
        grid[days.index(row["day"])][hours.index(int(row["hour"]))] = int(row["orders"])

for day, counts in zip(days, grid):
    busiest = hours[counts.index(max(counts))]
    print(f"{day}: busiest at {busiest}:00 with {max(counts)} orders, quietest {min(counts)}")

fig, ax = plt.subplots(figsize=(8, 3))
image = ax.imshow(grid, cmap="Blues", aspect="auto")
ax.set_xticks(range(len(hours)), hours)
ax.set_yticks(range(len(days)), days)
fig.colorbar(image, label="orders")
fig.savefig("week.png", dpi=150, bbox_inches="tight")
PY
block week
on '.venv/bin/python week.py'

put corr.py <<'PY'
import csv
import numpy as np

columns = ["km", "items", "rain", "basket", "minutes"]
with open("deliveries.csv") as f:
    rows = list(csv.DictReader(f))
data = np.array([[float(r[c]) for c in columns] for r in rows])

matrix = np.corrcoef(data, rowvar=False)
print(" " * 8 + "".join(f"{c:>8}" for c in columns))
for name, values in zip(columns, matrix):
    print(f"{name:8}" + "".join(f"{v:8.2f}" for v in values))
PY
block corr
on '.venv/bin/python corr.py'
