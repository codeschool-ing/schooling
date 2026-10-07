#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of visualization, as a script that
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
# NOT RECORDED: Excel, Power BI and Tableau. This lesson describes them and
# quotes nothing from them, because none of them runs in the machine these
# lessons were recorded on. Every transcript here is from matplotlib.
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

put plain.py <<'PY'
import csv
import matplotlib
import matplotlib.pyplot as plt

totals = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        if row["month"].startswith("2025"):
            totals[row["region"]] = totals.get(row["region"], 0) + int(row["orders"])

regions = sorted(totals, key=totals.get)
fig, ax = plt.subplots(figsize=(6, 3))
ax.barh(regions, [totals[r] for r in regions], color="#2b52c9")
ax.set_title("Southeast takes more orders than the next two regions together", loc="left")
ax.spines[["top", "right"]].set_visible(False)
fig.savefig("chart.svg")
print("matplotlib", matplotlib.__version__)
PY
# The two hashes this block prints are different on every run, and different
# from the ones quoted in the lesson. That is what the block is for.
block plain
on '.venv/bin/python plain.py && sha256sum chart.svg'
on '.venv/bin/python plain.py && sha256sum chart.svg'
put chart.py <<'PY'
import csv
import matplotlib
import matplotlib.pyplot as plt

matplotlib.rcParams["svg.hashsalt"] = "horta"

totals = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        if row["month"].startswith("2025"):
            totals[row["region"]] = totals.get(row["region"], 0) + int(row["orders"])

regions = sorted(totals, key=totals.get)
fig, ax = plt.subplots(figsize=(6, 3))
ax.barh(regions, [totals[r] for r in regions], color="#2b52c9")
ax.set_title("Southeast takes more orders than the next two regions together", loc="left")
ax.spines[["top", "right"]].set_visible(False)
fig.savefig("chart.svg", metadata={"Date": None})
print("matplotlib", matplotlib.__version__)
PY
block fixed
on '.venv/bin/python chart.py && sha256sum chart.svg'
on '.venv/bin/python chart.py && sha256sum chart.svg'
