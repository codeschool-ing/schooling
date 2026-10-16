#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of qa-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. tickets.py and both versions of
# cases.py are read out of the lessons by lab/extract.py; `version cases.py 1`
# puts back the first, so each run uses the file the section shows at that
# point. The trace module is Python's own; nothing is installed.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-znxd2f41 <<'S'
version cases.py 1
block trace
on 'python -m trace --count --missing --summary -C . cases.py'

block cover
on 'ls *.cover'
on 'cat *tickets.cover'

version cases.py 2
rm -f *.cover
block sixtyone
on 'python -m trace --count --missing --summary -C . cases.py'
on 'grep -A1 "age > 60" *tickets.cover'
S
