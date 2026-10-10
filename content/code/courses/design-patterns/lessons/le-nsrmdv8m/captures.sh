#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - in "composition-root", LIBRARY_TODAY fixes the day the program reads, so
#     the output does not depend on the date of the recording.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/injection"

block inversion-of-control
at injection
put "$HERE/inversion-of-control.md" desk.py
run python3 desk.py

block constructor-injection
put "$HERE/constructor-injection.md" overdue.py
run python3 overdue.py

block other-forms
put "$HERE/other-forms.md" forms.py
run python3 forms.py

block composition-root
put "$HERE/composition-root.md" main.py
run LIBRARY_TODAY=2026-03-20 python3 main.py
run LIBRARY_TODAY=2026-03-20 python3 main.py sms

block containers
put "$HERE/containers.md" container.py
put "$HERE/containers.md" wired.py
run python3 wired.py

block service-locator
put "$HERE/service-locator.md" locator.py
run python3 locator.py

block testing-with-fakes
put "$HERE/testing-with-fakes.md" test_overdue.py
run python3 -m unittest -v test_overdue.py
exit 0
