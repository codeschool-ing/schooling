#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - shelf.py, counting.py and loans.py each have two versions in the lesson,
#     and each run below extracts the version the prose has the student
#     holding at that point (the third argument of `put`).
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/composition"
at composition

block fragile-double
put "$HERE/fragile-base-class.md" shelf.py 1
put "$HERE/fragile-base-class.md" counting.py 1
run python3 counting.py

block fragile-fixed
put "$HERE/fragile-base-class.md" counting.py 2
run python3 counting.py

block fragile-broken
put "$HERE/fragile-base-class.md" shelf.py 2
run python3 counting.py

block explosion
put "$HERE/class-explosion.md" explosion.py
run python3 explosion.py

block delegation
put "$HERE/delegation.md" counted.py
run python3 counted.py
put "$HERE/fragile-base-class.md" shelf.py 1
run python3 counted.py

block swapping
put "$HERE/swapping-behaviour.md" fines.py
run python3 fines.py
put "$HERE/swapping-behaviour.md" test_fines.py
run python3 -m unittest -v test_fines.py

block fits
put "$HERE/when-inheritance-fits.md" fits.py
run python3 fits.py

block mixins
put "$HERE/mixins.md" mixins.py
run python3 mixins.py

block refactor
put "$HERE/refactor-to-composition.md" loans.py 1
put "$HERE/refactor-to-composition.md" test_loans.py
run python3 -m unittest -v test_loans.py
put "$HERE/refactor-to-composition.md" loans.py 2
run python3 -m unittest -v test_loans.py
exit 0
