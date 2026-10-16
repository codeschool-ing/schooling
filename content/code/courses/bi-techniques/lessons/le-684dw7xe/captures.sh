#!/usr/bin/env bash
# The program outputs quoted in lesson 18 of bi-techniques, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every example's
# output in this lesson was copied from running it:
#
#   sudo bash ../../lab.sh ready     # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: the environment and the data, as
# lesson 1 builds them, and scored.csv, which lesson 17's churn_model.py
# writes. It is saved from lesson 17's own page and run first, silently.
#
# Recorded on Ubuntu 24.04, Python 3.13, pandas 3.0.6, scikit-learn 1.9.1,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab-capture.sh"

lab reset >/dev/null
save "$HERE/../le-h2n7f1yg/the-churn-model.md" churn_model.py
lab exec ".venv/bin/python churn_model.py" >/dev/null
for p in the-audit:bias_audit.py finding-the-cause:rhythm.py; do
  save "$HERE/${p%%:*}.md" "${p#*:}"
  block "${p#*:}"
  on ".venv/bin/python ${p#*:}"
done
