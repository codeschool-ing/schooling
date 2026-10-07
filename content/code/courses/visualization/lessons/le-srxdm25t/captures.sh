#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of visualization, as a script that
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

put responsive.py <<'PY'
import csv
import os
import matplotlib.pyplot as plt

total = {}
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        total[row["month"]] = total.get(row["month"], 0) + int(row["orders"])
months = sorted(total)
values = [total[m] for m in months]
y24, y25 = sum(values[:12]), sum(values[12:])

def trend(name, size, ticks):
    fig, ax = plt.subplots(figsize=size)
    ax.plot(range(len(months)), values, color="#2b52c9", linewidth=2)
    ax.set_xticks(ticks, [months[i] for i in ticks])
    ax.set_title("Orders per month", loc="left")
    ax.spines[["top", "right"]].set_visible(False)
    fig.savefig(name, bbox_inches="tight")
    plt.close(fig)

trend("trend-wide.svg", (9, 3.5), [0, 6, 12, 18, 23])
trend("trend-narrow.svg", (3.6, 3.2), [0, 23])

page = f"""<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Horta</title>
<style>
  body {{ font-family: sans-serif; margin: 16px; max-width: 960px; }}
  .cards {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }}
  .card {{ border: 1px solid #ccd4e3; border-radius: 6px; padding: 12px; }}
  .card b {{ display: block; font-size: 2rem; }}
  img {{ width: 100%; height: auto; margin-top: 16px; }}
  @media (max-width: 600px) {{
    .cards {{ grid-template-columns: 1fr; }}
  }}
</style>
<div class="cards">
  <div class="card">orders in 2025 <b>{y25:,}</b> {y25 / y24 - 1:+.1%} on 2024</div>
  <div class="card">orders in December <b>{values[-1]:,}</b> {values[-1] / values[11] - 1:+.1%} on Dec 2024</div>
</div>
<picture>
  <source media="(max-width: 600px)" srcset="trend-narrow.svg">
  <img src="trend-wide.svg" alt="Orders per month, January 2024 to December 2025, rising from {values[0]:,} to {values[-1]:,} with a spike every December.">
</picture>
"""
with open("dashboard.html", "w") as f:
    f.write(page)

for name in ("dashboard.html", "trend-wide.svg", "trend-narrow.svg"):
    print(f"{name:16} {os.path.getsize(name):7,} bytes")
PY
block responsive
on '.venv/bin/python responsive.py'
block serve
on 'timeout 3 python3 -u -m http.server 8000 --bind 127.0.0.1'
