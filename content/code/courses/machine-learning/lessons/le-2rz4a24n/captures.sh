#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l15.txt
#   python3 ../../lab/paste.py --check . /tmp/l15.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, feira.py as lesson 2 prints
# it, and tuning.py as lesson 9 prints it. Every program is read out of the
# section that prints it. The two unseeded lines of seeds.py differ from run to
# run by design; the lesson's prose quotes the run pasted here.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/../le-c0jmyf75/the-search-score.md" tuning.py
save "$HERE/by-hand.md" by_hand.py
save "$HERE/transformers.md" contract.py
save "$HERE/a-pipeline.md" churn_model.py
save "$HERE/a-pipeline.md" pipeline.py
save "$HERE/searching-a-pipeline.md" search.py
save "$HERE/new-data.md" score_2026.py
save "$HERE/reproducibility.md" seeds.py

for name in by_hand contract pipeline search score_2026 seeds; do
  block "${name//_/-}"
  on "python $name.py"
done
