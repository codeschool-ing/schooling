#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh > out.txt   # needs the lab lesson 1 builds
#
# It puts ~/ml back to the shop as lesson 1 leaves it, stages the programs of
# lessons 1 and 2 this lesson imports, then saves each program this lesson
# shows (read out of the lesson, stage below) and runs it.
#
# A line that starts with ana@dev:~/ml$ is what ana typed and what it printed.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9

quiet lab project
stage features.py le-xpaf8cg8/supervised.md
stage regress.py le-mk4sta32/regression.md
stage model.py le-fcd08ha8/the-trap.md

for step in the-trap:accuracy four-kinds-of-answer:confusion choosing-a-threshold:thresholds \
            scores-for-a-ranking:ranking calibration:calibration regression-errors:errors; do
  section=${step%%:*} program=${step##*:}
  stage $program.py le-fcd08ha8/$section.md
  block $section
  on "python $program.py"
done
