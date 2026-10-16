#!/usr/bin/env bash
# The terminal session quoted in lesson 22 of qa-fundamentals, as a script
# that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. defects.csv and metrics.py are read
# out of the lesson by lab/extract.py, exactly as printed.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-16.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-8pev9zcy <<'S'
block metrics
on 'python metrics.py'
S
