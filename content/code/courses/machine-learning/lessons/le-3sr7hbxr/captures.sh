#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l16.txt
#   python3 ../../lab/paste.py --check . /tmp/l16.txt
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
save "$HERE/no-labels.md" baskets.py
save "$HERE/k-means.md" kmeans.py
save "$HERE/scale-first.md" unscaled.py
save "$HERE/choosing-k.md" choose_k.py
save "$HERE/dbscan.md" dbscan.py
save "$HERE/hierarchical.md" hierarchy.py
save "$HERE/is-it-real.md" stability.py

for name in baskets kmeans unscaled choose_k dbscan hierarchy stability; do
  block "${name//_/-}"
  on "python $name.py"
done
