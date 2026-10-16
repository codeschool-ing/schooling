#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l10.txt
#   python3 ../../lab/paste.py --check . /tmp/l10.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, and feira.py as lesson 2
# prints it. Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/confusion-matrix.md" scores.py
save "$HERE/confusion-matrix.md" confusion.py
save "$HERE/accuracy.md" metrics.py
save "$HERE/roc-auc.md" ranking.py

block scores
on 'python scores.py'
block confusion
on 'python confusion.py'
block metrics
on 'python metrics.py'
block ranking
on 'python ranking.py'
