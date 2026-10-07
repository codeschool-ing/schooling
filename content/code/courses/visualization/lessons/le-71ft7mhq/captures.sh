#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of visualization, as a script that
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

put dashboard.py <<'PY'
import csv
import statistics
import matplotlib.pyplot as plt

months, total = [], {}
by_region = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        m, n = row["month"], int(row["orders"])
        total[m] = total.get(m, 0) + n
        year = by_region.setdefault(row["region"], {"2024": 0, "2025": 0})
        year[m[:4]] += n
months = sorted(total)

with open("deliveries.csv") as f:
    minutes = [float(row["minutes"]) for row in csv.DictReader(f)]

y24 = sum(v for m, v in total.items() if m.startswith("2024"))
y25 = sum(v for m, v in total.items() if m.startswith("2025"))
kpis = [
    ("orders in 2025", f"{y25:,}", f"{y25 / y24 - 1:+.1%} on 2024"),
    ("orders in December", f"{total['2025-12']:,}", f"{total['2025-12'] / total['2024-12'] - 1:+.1%} on Dec 2024"),
    ("median delivery", f"{statistics.median(minutes):.0f} min",
     f"{sum(m > 45 for m in minutes) / len(minutes):.1%} over 45 min"),
]
for label, value, compare in kpis:
    print(f"{label:20} {value:>10}   {compare}")

fig = plt.figure(figsize=(9, 5.5))
grid = fig.add_gridspec(2, 3, height_ratios=[1, 3], hspace=0.4, wspace=0.5)
for i, (label, value, compare) in enumerate(kpis):
    ax = fig.add_subplot(grid[0, i])
    ax.axis("off")
    ax.text(0, 0.75, label, fontsize=10, color="#5a6274")
    ax.text(0, 0.3, value, fontsize=22, fontweight="bold")
    ax.text(0, 0.0, compare, fontsize=9, color="#5a6274")

trend = fig.add_subplot(grid[1, :2])
trend.plot(range(len(months)), [total[m] for m in months], color="#2b52c9", linewidth=2)
trend.set_xticks([0, 6, 12, 18, 23], [months[i] for i in (0, 6, 12, 18, 23)])
trend.set_title("Orders per month", loc="left")
trend.spines[["top", "right"]].set_visible(False)

growth = {r: v["2025"] / v["2024"] - 1 for r, v in by_region.items()}
names = sorted(growth, key=growth.get)
side = fig.add_subplot(grid[1, 2])
side.barh(names, [100 * growth[r] for r in names], color="#767676")
side.set_title("Growth, 2025 on 2024 (%)", loc="left")
side.spines[["top", "right"]].set_visible(False)
fig.savefig("dashboard.png", dpi=120, bbox_inches="tight")
PY
block dashboard
on '.venv/bin/python dashboard.py'
