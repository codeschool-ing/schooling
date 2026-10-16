#!/usr/bin/env bash
# The terminal session quoted in lesson 21 of qa-fundamentals, as a script
# that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds, with behave 1.3.3 in its virtual
# environment. Every program the course has printed so far is read out of the
# lessons by lab/extract.py, in its latest version: the build Lia's cycle
# starts from is everything up to lesson 17.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, behave 1.3.3, on 2026-10-16.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-93tkc3rw <<'S'
block smoke
on 'python -m unittest'
on 'behave --format progress'
on 'python tickets.py 35 no thu 20:00'
S
