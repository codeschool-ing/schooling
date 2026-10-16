#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of qa-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. coupons.py and test_coupons.py are
# read out of the lessons by lab/extract.py, every version the lesson prints;
# `version NAME N` puts the Nth one in place before each run, so each red and
# each green is the run of exactly the files printed above it. The first block
# removes coupons.py, because the first red is the run with no code at all.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-11.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-5by4rvav <<'S'
rm -f coupons.py
version test_coupons.py 1
block red1
on 'python -m unittest -v'

version coupons.py 1
block green1
on 'python -m unittest -v'

version test_coupons.py 2
block red2
on 'python -m unittest -v'

version coupons.py 2
block green2
on 'python -m unittest -v'

version test_coupons.py 3
block red3
on 'python -m unittest -v'

version coupons.py 3
block green3
on 'python -m unittest -v'

version coupons.py 4
block refactor
on 'python -m unittest -v'

version test_coupons.py 4
block red4
on 'python -m unittest -v'

version coupons.py 5
block green4
on 'python -m unittest -v'
S
