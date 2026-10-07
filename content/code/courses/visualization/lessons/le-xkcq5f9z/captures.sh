#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of visualization, as a script that
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

put palettes.py <<'PY'
import sys
import matplotlib
from matplotlib.colors import to_hex


def lightness(rgb):
    r, g, b = ((c / 12.92) if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb[:3])
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s


for name in sys.argv[1:]:
    cmap = matplotlib.colormaps[name]
    samples = [cmap(i / 6) for i in range(7)]
    print(f"{name:8}", " ".join(to_hex(c) for c in samples))
    print(f"{'':8}", " ".join(f"{lightness(c):7.2f}" for c in samples))
PY
block palettes
on '.venv/bin/python palettes.py viridis cividis jet RdBu'
