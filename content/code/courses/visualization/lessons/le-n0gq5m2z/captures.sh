#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of visualization, as a script that
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

put rates.py <<'PY'
import csv
import numpy as np

with open("states.csv") as f:
    rows = list(csv.DictReader(f))
for r in rows:
    r["rate"] = int(r["orders"]) / (float(r["population"]) * 1000)

by_orders = sorted(rows, key=lambda r: int(r["orders"]), reverse=True)
by_rate = sorted(rows, key=lambda r: r["rate"], reverse=True)
print("most orders:", ", ".join(r["state"] for r in by_orders[:5]))
print("best rate:  ", ", ".join(f'{r["state"]} {r["rate"]:.2f}' for r in by_rate[:5]))
print("worst rate: ", ", ".join(f'{r["state"]} {r["rate"]:.2f}' for r in by_rate[-3:]))

rates = np.array([r["rate"] for r in rows])
print("equal intervals:", np.round(np.linspace(rates.min(), rates.max(), 5), 2))
print("quantiles:      ", np.round(np.percentile(rates, [0, 25, 50, 75, 100]), 2))
PY
block rates
on '.venv/bin/python rates.py'
