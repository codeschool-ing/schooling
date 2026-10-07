#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of visualization, as a script that
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

put scatter.py <<'PY'
import csv
import numpy as np
import matplotlib.pyplot as plt

with open("deliveries.csv") as f:
    rows = list(csv.DictReader(f))
km = np.array([float(r["km"]) for r in rows])
minutes = np.array([float(r["minutes"]) for r in rows])

slope, intercept = np.polyfit(km, minutes, 1)
r = np.corrcoef(km, minutes)[0, 1]
print(f"minutes = {intercept:.1f} + {slope:.2f} x km")
print(f"r = {r:.2f}, r squared = {r * r:.2f}")
print(f"km in the data: {km.min()} to {km.max()}")
for distance in [5, 20, 60]:
    print(f"at {distance:2} km the line says {intercept + slope * distance:5.1f} minutes")

fig, ax = plt.subplots(figsize=(6, 4))
ax.scatter(km, minutes, s=12, alpha=0.5)
ax.plot([0, km.max()], [intercept, intercept + slope * km.max()], color="#d40f28")
ax.set_xlabel("distance (km)")
ax.set_ylabel("delivery time (minutes)")
fig.savefig("scatter.png", dpi=150, bbox_inches="tight")
PY
block scatter
on '.venv/bin/python scatter.py'

put states.py <<'PY'
import csv

with open("states.csv") as f:
    rows = list(csv.DictReader(f))
orders = sorted(int(r["orders"]) for r in rows)
people = sorted(float(r["population"]) for r in rows)
print(f"orders:     {orders[0]:6} to {orders[-1]:6}, ratio {orders[-1] / orders[0]:.0f}")
print(f"population: {people[0]:6} to {people[-1]:6}, ratio {people[-1] / people[0]:.0f}")
below = sum(1 for o in orders if o < orders[-1] / 10)
print(f"{below} of {len(orders)} states have under a tenth of the largest")
PY
block states
on '.venv/bin/python states.py'
