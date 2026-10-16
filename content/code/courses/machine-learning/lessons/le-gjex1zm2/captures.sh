#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l13.txt
#   python3 ../../lab/paste.py --check . /tmp/l13.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, and feira.py as lesson 2
# prints it. Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/the-rare-class.md" balance.py
save "$HERE/too-few.md" few.py
save "$HERE/class-weights.md" rebalance.py
save "$HERE/resampling-leaks.md" leak.py
save "$HERE/correcting-chances.md" correct.py

for name in balance few rebalance leak correct; do
  block "$name"
  on "python $name.py"
done
