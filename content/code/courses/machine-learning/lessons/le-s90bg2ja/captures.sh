#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l18.txt
#   python3 ../../lab/paste.py --check . /tmp/l18.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it. Every program is read out of
# the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/the-matrix.md" holdout.py
save "$HERE/the-matrix.md" matrix.py
save "$HERE/popularity.md" popular.py
save "$HERE/similar-items.md" similar.py
save "$HERE/item-based.md" item_based.py
save "$HERE/factors.md" factors.py
save "$HERE/cold-start.md" cold_start.py

for name in matrix popular similar item_based factors cold_start; do
  block "${name//_/-}"
  on "python $name.py"
done
