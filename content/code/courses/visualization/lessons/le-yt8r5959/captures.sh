#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of visualization, as a script that
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

put colours.py <<'PY'
import colorsys
import sys


def channels(hex_colour):
    return [int(hex_colour[i:i + 2], 16) / 255 for i in (1, 3, 5)]


def linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def oklab_lightness(rgb):
    r, g, b = (linear(c) for c in rgb)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s


print("colour     hue  sat  light(HSL)  luminance  OKLab L")
for hex_colour in sys.argv[1:]:
    rgb = channels(hex_colour)
    h, l, s = colorsys.rgb_to_hls(*rgb)
    r, g, b = (linear(c) for c in rgb)
    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    print(f"{hex_colour}  {h * 360:4.0f} {s:4.0%}  {l:9.0%}  {luminance:9.3f}  {oklab_lightness(rgb):7.3f}")
PY
block six
on '.venv/bin/python colours.py "#ff0000" "#ffff00" "#00ff00" "#00ffff" "#0000ff" "#ff00ff"'
