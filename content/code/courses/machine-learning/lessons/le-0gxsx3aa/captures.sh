#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l12.txt
#   python3 ../../lab/paste.py --check . /tmp/l12.txt
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
save "$HERE/four-predictions.md" predictions.py
save "$HERE/four-predictions.md" errors.py
save "$HERE/rmse.md" outliers.py
save "$HERE/mape.md" mape.py
save "$HERE/r-squared.md" r2.py
save "$HERE/direction.md" direction.py
save "$HERE/promises.md" promise.py

for name in predictions errors outliers mape r2 direction promise; do
  block "$name"
  on "python $name.py"
done
