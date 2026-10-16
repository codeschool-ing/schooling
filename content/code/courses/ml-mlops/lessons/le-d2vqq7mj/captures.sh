#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh > out.txt   # needs the lab lesson 1 builds
#
# It puts ~/ml back to the shop as lesson 1 leaves it, stages features.py and
# model.py from lessons 1 and 4, then saves each program this lesson shows
# (read out of the lesson, stage below) and runs it.
#
# A line that starts with ana@dev:~/ml$ or ana@dev:~$ is what ana typed and
# what it printed. Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9

quiet lab project
stage features.py le-xpaf8cg8/supervised.md
stage model.py le-fcd08ha8/the-trap.md
stage project.py le-d2vqq7mj/from-scripts-to-steps.md

stage build_dataset.py le-d2vqq7mj/building-the-dataset.md
block building-the-dataset
on 'python build_dataset.py 2025-08-31 data/train.csv'
on 'python build_dataset.py 2025-11-30 data/test.csv'
on '(cd /tmp && python ~/ml/build_dataset.py 2026-01-31 data/jan.csv); echo "exit status $?"'
on 'ls data'

stage validate.py le-d2vqq7mj/a-data-contract.md
block a-data-contract
on 'python validate.py data/train.csv'
on 'python validate.py data/test.csv'
on "python -c \"import pandas as pd; r = pd.read_csv('data/train.csv'); r.loc[:9, 'recency_days'] -= 200; pd.concat([r, r.head(5)]).to_csv('data/broken.csv', index=False)\""
on 'python validate.py data/broken.csv; echo "exit status $?"'

stage train.py le-d2vqq7mj/training-as-a-step.md
block training-as-a-step
on 'python train.py data/train.csv models/lapse.joblib'

stage evaluate.py le-d2vqq7mj/evaluating-as-a-step.md
block evaluating-as-a-step
on 'python evaluate.py models/lapse.joblib data/test.csv'

stage pipeline.sh le-d2vqq7mj/running-the-pipeline.md
block running-the-pipeline
home 'sh ml/pipeline.sh'

stage skew.py le-d2vqq7mj/training-serving-skew.md
block training-serving-skew
on 'python skew.py'
