#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l17.txt
#   python3 ../../lab/paste.py --check . /tmp/l17.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, feira.py as lesson 2 prints
# it, and churn_model.py as lesson 15 prints it. Every program is read out of
# the section that prints it. The seconds in maps.py are this machine's.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/../le-2rz4a24n/a-pipeline.md" churn_model.py
save "$HERE/pca.md" pca.py
save "$HERE/pictures.md" maps.py
save "$HERE/new-points.md" new_points.py
save "$HERE/pca-in-a-model.md" pca_model.py

for name in pca maps new_points pca_model; do
  block "${name//_/-}"
  on "python $name.py"
done
