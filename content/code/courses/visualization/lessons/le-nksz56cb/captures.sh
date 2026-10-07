#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of visualization, as a script that
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

put boxes.py <<'PY'
import csv
import numpy as np
import matplotlib.pyplot as plt

groups = {}
with open("deliveries.csv") as f:
    for row in csv.DictReader(f):
        groups.setdefault(row["region"], []).append(float(row["minutes"]))

print("region         n    min     Q1  median     Q3    max  beyond")
for region, values in groups.items():
    v = np.array(values)
    q1, med, q3 = np.percentile(v, [25, 50, 75])
    fence = q3 + 1.5 * (q3 - q1)
    beyond = int((v > fence).sum())
    print(f"{region:12} {len(v):3} {v.min():6.1f} {q1:6.1f} {med:6.1f} "
          f"{q3:6.1f} {v.max():6.1f} {beyond:6}")

fig, ax = plt.subplots(figsize=(7, 3.5))
ax.boxplot(list(groups.values()), tick_labels=list(groups.keys()))
ax.set_ylabel("delivery time (minutes)")
fig.savefig("boxes.png", dpi=150, bbox_inches="tight")
PY
block boxes
on '.venv/bin/python boxes.py'
