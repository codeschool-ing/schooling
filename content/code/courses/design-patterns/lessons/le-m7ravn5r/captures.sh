#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - nothing else. hops.py and smells.py read plain.py and layered.py, which
#     are put in place first, as the student has them from the section before.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/choosing"

block cost
at choosing
put "$HERE/the-cost-of-a-pattern.md" plain.py
put "$HERE/the-cost-of-a-pattern.md" layered.py
run python3 plain.py
run python3 layered.py
run wc -l plain.py layered.py
put "$HERE/the-cost-of-a-pattern.md" hops.py
run python3 hops.py

block smells
put "$HERE/over-design-signs.md" smells.py
run python3 smells.py layered.py plain.py

block decisions
put "$HERE/worked-decisions.md" policies.py
run python3 policies.py

block reading
put "$HERE/reading-a-codebase.md" mystery.py
run python3 mystery.py
exit 0
