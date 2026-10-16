#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of qa-fundamentals, as a script
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
# staged: every line is a command typed and what it printed, tracebacks
# included.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-95zfqkkw <<'S'
block cases
on 'python tickets.py 35 no thu 16:59'
on 'python tickets.py 35 no thu 17:00'
on 'python tickets.py 20 yes thu 20:00'
on 'python tickets.py 11 no thu 20:00'
on 'python tickets.py 12 no thu 20:00'
on 'python tickets.py 35 no wed 20:00'

block wednesday
on 'python tickets.py 20 yes wed 20:00'
on 'python tickets.py 8 no wed 14:00'
on 'python tickets.py 70 no wed 20:00'

block crash
on 'python tickets.py sixty no thu 20:00'
on 'python tickets.py 35 no thu'

block quiet
on 'python tickets.py -5 no thu 20:00'
on 'python tickets.py 35 maybe thu 20:00'
on 'python tickets.py 35 no Wed 20:00'
on 'python tickets.py 35 no thu 25:00'
S
