#!/usr/bin/env bash
# The program outputs quoted in lesson 2 of bi-techniques, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every example's
# output in this lesson was copied from running it:
#
#   sudo bash ../../lab.sh ready     # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: the environment and the data, as
# lesson 1 builds them. Each program is saved from this lesson's own page.
#
# Recorded on Ubuntu 24.04, Python 3.13, pandas 3.0.6, statsmodels 0.15.0,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab-capture.sh"

lab reset >/dev/null
for p in moving-averages:moving.py additive-or-multiplicative:swing.py \
         classical-decomposition:decompose.py stl:stl.py seasonally-adjusted:adjusted.py; do
  save "$HERE/${p%%:*}.md" "${p#*:}"
  block "${p#*:}"
  on ".venv/bin/python ${p#*:}"
done
