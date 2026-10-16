#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of qa-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds, with behave 1.3.3 in its virtual
# environment. tickets.py, coupons.py, both feature files and both step files
# are read out of the lessons by lab/extract.py. The first run is against
# lesson 1's tickets.py, the version with the defects; `version tickets.py 2`
# puts this lesson's fix in place for the second.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, behave 1.3.3, on 2026-10-16.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-thq1vdxz <<'S'
version tickets.py 1
block outline-red
on 'behave features/prices.feature'

version tickets.py 2
block outline-green
on 'behave features/prices.feature'

block everything
on 'behave --format progress'
S
