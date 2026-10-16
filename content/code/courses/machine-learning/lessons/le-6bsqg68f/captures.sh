#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l11.txt
#   python3 ../../lab/paste.py --check . /tmp/l11.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, feira.py as lesson 2 prints
# it, and scores.csv as lesson 10's scores.py writes it (run here, quietly).
# Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/../le-fmw2rq2f/confusion-matrix.md" scores.py
quiet 'python scores.py'
save "$HERE/the-value-curve.md" sweep.py
save "$HERE/honest-chances.md" reliability.py
save "$HERE/what-changed.md" by_month.py
save "$HERE/calibration.md" calibrate.py
save "$HERE/choosing-the-cut.md" choose_cut.py
save "$HERE/capacity.md" capacity.py
save "$HERE/when-the-costs-move.md" sensitivity.py

for name in sweep reliability by_month calibrate choose_cut capacity sensitivity; do
  block "${name//_/-}"
  on "python $name.py"
done
