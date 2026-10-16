#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l2.txt
#   python3 ../../lab/paste.py --check . /tmp/l2.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it. Every program is read out of
# the section that prints it, feira.py included, and saved into ~/ml before
# it runs. beaten.py reads first_model_scores.csv, which first_model.py
# writes, so the order below is the order the lesson takes.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/a-module.md" feira.py
save "$HERE/the-majority-class.md" dummy.py
save "$HERE/a-rule-of-thumb.md" rule.py
save "$HERE/the-first-model.md" first_model.py
save "$HERE/beaten-by-chance.md" beaten.py
save "$HERE/regression-baselines.md" delivery_baselines.py

block dummy
on 'python dummy.py'
block rule
on 'python rule.py'
block first-model
on 'python first_model.py'
block beaten
on 'python beaten.py'
block delivery-baselines
on 'python delivery_baselines.py'
