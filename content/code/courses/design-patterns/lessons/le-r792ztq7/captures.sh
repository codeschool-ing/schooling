#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - nothing else: the two desks of desks.py are interleaved by the program
#     itself in one thread, and latency.py's milliseconds are constants it
#     declares, so every run prints the same lines.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/acid-cap"

block acid
at acid-cap
put "$HERE/acid.md" reserve.py
run python3 reserve.py

block isolation
put "$HERE/isolation.md" desks.py
run python3 desks.py

block unit-of-work
put "$HERE/unit-of-work.md" uow.py
run python3 uow.py

block cap
put "$HERE/cap.md" branches.py
run python3 branches.py

block pacelc
put "$HERE/pacelc.md" latency.py
run python3 latency.py
exit 0
