#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of visualization, as a script that
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

put multiples.py <<'PY'
import csv
import sys
import matplotlib.pyplot as plt

shared = sys.argv[1:] != ["free"]

series = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        series.setdefault(row["region"], []).append(int(row["orders"]))
regions = sorted(series, key=lambda r: series[r][-1], reverse=True)

fig, axes = plt.subplots(1, len(regions), figsize=(12, 2.5), sharey=shared)
for ax, region in zip(axes, regions):
    for other in regions:
        ax.plot(series[other], color="lightgrey", linewidth=0.8)
    ax.plot(series[region], color="#2b52c9", linewidth=2)
    ax.set_title(region)
    if not shared:
        ax.set_ylim(min(series[region]) * 0.95, max(series[region]) * 1.05)
    low, high = ax.get_ylim()
    print(f"{region:12} axis {low:6.0f} to {high:6.0f}")
fig.savefig("multiples.png", dpi=150, bbox_inches="tight")
PY
block shared
on '.venv/bin/python multiples.py'
block free
on '.venv/bin/python multiples.py free'
