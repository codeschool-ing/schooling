#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of visualization, as a script that
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

put access.py <<'PY'
import sys

# Machado, Oliveira and Fernandes (2009): full deuteranopia, applied to linear RGB.
DEUTAN = [[0.367322, 0.860646, -0.227968],
          [0.280085, 0.672501, 0.047413],
          [-0.011820, 0.042940, 0.968881]]


def to_linear(hex_colour):
    out = []
    for i in (1, 3, 5):
        c = int(hex_colour[i:i + 2], 16) / 255
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return out


def to_hex(linear):
    out = ""
    for c in linear:
        c = min(1.0, max(0.0, c))
        c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
        out += f"{round(c * 255):02x}"
    return "#" + out


def luminance(hex_colour):
    r, g, b = to_linear(hex_colour)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted([luminance(a), luminance(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)


def deutan(hex_colour):
    rgb = to_linear(hex_colour)
    return to_hex([sum(m * c for m, c in zip(row, rgb)) for row in DEUTAN])


for pair in sys.argv[1:]:
    a, b = pair.split(":")
    print(f"{a} on {b}: {contrast(a, b):5.2f} : 1   "
          f"as deuteranopia sees them, {deutan(a)} and {deutan(b)}: "
          f"{contrast(deutan(a), deutan(b)):5.2f} : 1")
PY
block pairs
on '.venv/bin/python access.py "#d62728:#2ca02c" "#d62728:#1f77b4" "#c8ccd4:#ffffff" "#767676:#ffffff" "#5a6274:#ffffff"'
