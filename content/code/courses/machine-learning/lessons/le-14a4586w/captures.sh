#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l3.txt
#   python3 ../../lab/paste.py --check . /tmp/l3.txt
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
save "$HERE/why-hold-out.md" overfit.py
save "$HERE/cross-validation.md" folds.py
save "$HERE/stratified.md" leavers_per_fold.py
save "$HERE/groups.md" groups.py
save "$HERE/time.md" time_split.py
save "$HERE/time.md" walk_forward.py

block overfit
on 'python overfit.py'
block folds
on 'python folds.py'
block leavers
on 'python leavers_per_fold.py'
block groups
on 'python groups.py'
block time-split
on 'python time_split.py'
block walk-forward
on 'python walk_forward.py'
