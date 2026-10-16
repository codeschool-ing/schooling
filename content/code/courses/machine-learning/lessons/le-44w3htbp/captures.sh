#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l22.txt
#   python3 ../../lab/paste.py --check . /tmp/l22.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, and feira.py as lesson 2
# prints it. Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/../le-2rz4a24n/a-pipeline.md" churn_model.py
save "$HERE/../le-0vgpfnjp/saving.md" stored.py
save "$HERE/../le-0vgpfnjp/saving.md" save_model.py
save "$HERE/the-monthly-run.md" monthly.py
save "$HERE/watching-inputs.md" inputs.py
save "$HERE/labels-arrive.md" labels.py
save "$HERE/where-it-broke.md" where.py
save "$HERE/refitting.md" refit.py
quiet 'python save_model.py'

block monthly
sess <<'CMDS'
for month in 2026-01-01 2026-02-01 2026-03-01; do python monthly.py $month; done
ls scores
head -3 scores/2026-03.csv
CMDS

for name in inputs labels where refit; do
  block "$name"
  on "python $name.py"
done
