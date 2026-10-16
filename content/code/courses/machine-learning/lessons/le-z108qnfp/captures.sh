#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l8.txt
#   python3 ../../lab/paste.py --check . /tmp/l8.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, and feira.py as lesson 2
# prints it. Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, XGBoost 3.4.1,
# LightGBM 4.7.0, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/bagging.md" bagging.py
save "$HERE/random-forest.md" forest.py
save "$HERE/boosting.md" boosting_steps.py
save "$HERE/early-stopping.md" hist_boost.py
save "$HERE/xgboost.md" xgb.py
save "$HERE/lightgbm.md" lgbm.py
save "$HERE/comparing.md" compare.py

block bagging
on 'python bagging.py'
block forest
on 'python forest.py'
block boosting-steps
on 'python boosting_steps.py'
block hist-boost
on 'python hist_boost.py'
block xgb
on 'python xgb.py'
block lgbm
on 'python lgbm.py'
block compare
on 'python compare.py'
