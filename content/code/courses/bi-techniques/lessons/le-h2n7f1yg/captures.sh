#!/usr/bin/env bash
# The program outputs quoted in lesson 17 of bi-techniques, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every example's
# output in this lesson was copied from running it:
#
#   sudo bash ../../lab.sh ready     # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: the environment and the data, as
# lesson 1 builds them. Each program is saved from this lesson's own page;
# churn_model.py writes scored.csv, which threshold.py reads.
#
# Recorded on Ubuntu 24.04, Python 3.13, pandas 3.0.6, scikit-learn 1.9.1,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab-capture.sh"

lab reset >/dev/null
for p in the-churn-model:churn_model.py choosing-a-threshold:threshold.py regression:spend_model.py; do
  save "$HERE/${p%%:*}.md" "${p#*:}"
  block "${p#*:}"
  on ".venv/bin/python ${p#*:}"
done
