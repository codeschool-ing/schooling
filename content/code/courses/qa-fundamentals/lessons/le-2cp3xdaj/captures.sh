#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of qa-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. tickets.py is read out of lesson 1
# by lab/extract.py, so the program run is the program printed. Nothing is
# staged: every line is a command typed and what it printed.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-2cp3xdaj <<'S'
block afternoon
on 'python tickets.py 35 no sun 15:00'
on 'python tickets.py 8 no sun 9:30'

block morning
on 'python tickets.py 35 no sun 9:30'
on 'python tickets.py 35 no sun 9:59'
on 'python tickets.py 35 no sun 10:00'
on 'python tickets.py 35 no sun 09:30'

block why
on "python -c 'print(\"10:00\" < \"17:00\")'"
on "python -c 'print(\"09:30\" < \"17:00\")'"
on "python -c 'print(\"9:30\" < \"17:00\")'"

block repro
on 'python tickets.py 35 no thu 09:30'
on 'python tickets.py 35 no thu 9:30'
S
