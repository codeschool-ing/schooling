#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh > out.txt   # needs the lab lesson 1 builds
#
# It puts ~/ml back to the shop as lesson 1 leaves it, then saves each program
# this lesson shows (read out of the lesson, stage below) and runs it.
#
# A line that starts with ana@dev:~/ml$ is what ana typed and what it printed.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9

quiet lab project
stage features.py le-xpaf8cg8/supervised.md

stage overfit.py le-mxa5a0m1/the-score-that-lies.md
block the-score-that-lies
on 'python overfit.py'

stage leak.py le-mxa5a0m1/the-summary-table.md
block the-summary-table
on 'python leak.py'

stage splits.py le-mxa5a0m1/stacked-cutoffs.md
block stacked-cutoffs
on 'python splits.py'

stage maturity.py le-mxa5a0m1/unfinished-labels.md
block unfinished-labels
on 'python maturity.py'
