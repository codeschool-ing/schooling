#!/usr/bin/env bash
# The terminal session quoted in lesson 19 of qa-fundamentals, as a script
# that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. tickets.py and relations.py are read
# out of the lessons by lab/extract.py; the tickets.py in place is lesson 17's,
# the version that passed every acceptance test, because that is the one the
# lesson says the check ran against.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-16.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-0tjby67b <<'S'
version tickets.py 2
block relations
on 'python relations.py'
S
