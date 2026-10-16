#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l9.txt
#   python3 ../../lab/paste.py --check . /tmp/l9.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, and feira.py as lesson 2
# prints it, and tuning.py as section `the-search-score`
# prints it. Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/the-search-score.md" tuning.py
save "$HERE/the-search-score.md" baseline_cv.py
save "$HERE/grid-search.md" grid.py
save "$HERE/random-search.md" random_search.py
save "$HERE/bayesian-search.md" bayes_search.py
save "$HERE/the-test-once.md" test_once.py

block baseline-cv
on 'python baseline_cv.py'
block grid
on 'python grid.py'
block random-search
on 'python random_search.py'
block bayes-search
on 'python bayes_search.py'
block test-once
on 'python test_once.py'
