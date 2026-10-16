#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of ml-mlops, as a script that
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

stage classify.py le-mk4sta32/classification.md
block classification
on 'python classify.py'

stage encode.py le-mk4sta32/encoding.md
block encoding
on 'python encode.py'

stage regress.py le-mk4sta32/regression.md
block regression
on 'python regress.py'

stage baseline.py le-mk4sta32/baselines.md
block baselines
on 'python baseline.py'

stage cluster.py le-mk4sta32/clustering.md
block clustering
on 'python cluster.py'

stage recommend.py le-mk4sta32/recommendation.md
block recommendation
on 'python recommend.py'
