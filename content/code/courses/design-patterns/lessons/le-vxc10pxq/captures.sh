#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. Files that change during
# the lesson are taken version by version (`put MD NAME K`), in the order the
# prose shows them. What is STAGED rather than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - in "slip", the subtraction in days_late reversed with sed before the run,
#     and fines.py extracted again after it, as the student would undo it.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/tdd"

block first-red
at tdd
put "$HERE/first-cycle.md" test_fines.py
run python3 -m unittest -v test_fines.py

block first-green
put "$HERE/first-cycle.md" fines.py
run python3 -m unittest -v test_fines.py

block typo
put "$HERE/first-cycle.md" test_typo.py
run python3 -m unittest -v test_typo.py

block second-example
put "$HERE/triangulation.md" test_fines.py 1
run python3 -m unittest test_fines.py
put "$HERE/triangulation.md" fines.py 1
run python3 -m unittest test_fines.py

block early-return
put "$HERE/triangulation.md" test_fines.py 2
run python3 -m unittest test_fines.py
put "$HERE/triangulation.md" fines.py 2
run python3 -m unittest test_fines.py

block refactor
put "$HERE/the-refactor-step.md" fines.py
run python3 test_fines.py

block slip
sed -i 's/(returned - due)/(due - returned)/' fines.py
run python3 test_fines.py
put "$HERE/the-refactor-step.md" fines.py

block refactor-tests
put "$HERE/the-refactor-step.md" test_fines.py
run python3 test_fines.py

block design
put "$HERE/tdd-and-design.md" reminders.py
put "$HERE/tdd-and-design.md" test_reminders.py
run python3 -m unittest -v test_reminders.py

block doubles
put "$HERE/doubles-in-tdd.md" notify.py 1
put "$HERE/doubles-in-tdd.md" test_notify.py
run python3 -m unittest -v test_notify.py
put "$HERE/doubles-in-tdd.md" notify.py 2
run python3 -m unittest -v test_notify.py
exit 0
