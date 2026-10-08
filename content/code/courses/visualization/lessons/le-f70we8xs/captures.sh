#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of visualization, as a script that
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

put annotate.py <<'PY'
import csv
import matplotlib.pyplot as plt

series, months = {}, []
with open("monthly.csv") as f:
    for row in csv.DictReader(f):
        series.setdefault(row["region"], []).append(int(row["orders"]))
        if row["month"] not in months:
            months.append(row["month"])

south, northeast = series["South"], series["Northeast"]
ahead = [n > s for n, s in zip(northeast, south)]
first = ahead.index(True)
for_good = max(i for i in range(len(ahead)) if not ahead[i]) + 1
print("Northeast first ahead:", months[first])
print("ahead for good from:  ", months[for_good])

fig, ax = plt.subplots(figsize=(7, 3.5))
ax.plot(south, color="#767676")
ax.plot(northeast, color="#2b52c9", linewidth=2.5)
ax.text(len(months) - 1 + 0.3, south[-1], "South", va="center", color="#767676")
ax.text(len(months) - 1 + 0.3, northeast[-1], "Northeast", va="center", color="#2b52c9")
ax.annotate(f"ahead from {months[for_good]}", xy=(for_good, northeast[for_good]),
            xytext=(for_good - 6, northeast[for_good] + 900),
            arrowprops={"arrowstyle": "->"})
ax.set_title("Northeast overtook South in late 2024 and kept pulling away", loc="left")
ax.set_ylabel("orders per month")
ax.spines[["top", "right"]].set_visible(False)
fig.savefig("annotate.png", dpi=150, bbox_inches="tight")
PY
block annotate
on '.venv/bin/python annotate.py'
