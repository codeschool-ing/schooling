#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of visualization, as a script that
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

put inkratio.py <<'PY'
import csv
import numpy as np
import matplotlib.pyplot as plt

names, revenue = [], []
with open("categories.csv") as f:
    for row in csv.DictReader(f):
        names.append(row["category"])
        revenue.append(int(row["revenue"]))

BLUE = (0x2B, 0x52, 0xC9)

def draw(clean):
    fig, ax = plt.subplots(figsize=(5, 3), dpi=100)
    ax.barh(names, revenue, color="#2b52c9", label="revenue (R$ thousand)")
    ax.invert_yaxis()
    if clean:
        ax.spines[["top", "right", "bottom"]].set_visible(False)
        ax.tick_params(left=False, bottom=False, labelbottom=False)
        ax.set_title("Revenue by category, R$ thousand", loc="left")
        for y, v in enumerate(revenue):
            ax.text(v + 5, y, f"{v}", va="center")
    else:
        ax.set_facecolor("#d9d9d9")
        ax.grid(color="black", linewidth=1)
        ax.set_axisbelow(True)
        ax.legend()
    fig.canvas.draw()
    rgb = np.asarray(fig.canvas.buffer_rgba())[:, :, :3].astype(int)
    fig.savefig("clean.png" if clean else "cluttered.png", bbox_inches="tight")
    plt.close(fig)
    ink = (rgb < 250).any(axis=2).sum()
    data = (np.abs(rgb - BLUE).sum(axis=2) < 30).sum()
    return data, ink

for clean in (False, True):
    data, ink = draw(clean)
    name = "clean" if clean else "cluttered"
    print(f"{name:9}  ink {ink:6} px  bars {data:6} px  data-ink ratio {data / ink:.2f}")
PY
block inkratio
on '.venv/bin/python inkratio.py'
