#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of visualization, as a script that
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

put bins.py <<'PY'
import csv
import numpy as np

with open("deliveries.csv") as f:
    minutes = np.array([float(row["minutes"]) for row in csv.DictReader(f)])

print(f"{len(minutes)} deliveries, from {minutes.min()} to {minutes.max()} minutes")
q1, median, q3 = np.percentile(minutes, [25, 50, 75])
print(f"median {median:.2f}, quartiles {q1:.2f} and {q3:.2f}")

for rule in ["sturges", "sqrt", "fd"]:
    edges = np.histogram_bin_edges(minutes, bins=rule)
    print(f"{rule:8} {len(edges) - 1:3} bins of {edges[1] - edges[0]:5.2f} minutes")
PY
block bins
on '.venv/bin/python bins.py'

put histogram.py <<'PY'
import csv
import matplotlib.pyplot as plt

with open("deliveries.csv") as f:
    minutes = [float(row["minutes"]) for row in csv.DictReader(f)]

fig, axes = plt.subplots(1, 3, figsize=(10, 3), sharey=False)
for ax, width in zip(axes, [2, 5, 15]):
    edges = list(range(0, 106, width))
    counts, _, _ = ax.hist(minutes, bins=edges, edgecolor="white")
    ax.set_title(f"bins of {width} minutes")
    print(f"width {width:2}: {len(edges) - 1:2} bins, tallest holds {int(max(counts))}")
fig.savefig("histograms.png", dpi=150, bbox_inches="tight")
PY
block histogram
on '.venv/bin/python histogram.py'
