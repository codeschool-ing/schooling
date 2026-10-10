#!/usr/bin/env bash
# The terminal session quoted in lesson 3 of qa-fundamentals, as a script
# that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. tickets.py and overcharge.py are read
# out of the lessons by lab/extract.py, so the programs run are the programs
# printed. The month of sales is generated from a fixed seed inside the
# program, so the numbers are the same on every run.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-hpbw7my8 <<'S'
block month
on 'python overcharge.py'
S
