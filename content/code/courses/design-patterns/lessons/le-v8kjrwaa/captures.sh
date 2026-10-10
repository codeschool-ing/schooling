#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. report.py is taken in
# the version each section shows, and test_report.py likewise (`put MD NAME K`).
# What is STAGED rather than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - in "slip", the padding dropped from money() with sed before the run, and
#     report.py extracted again after it, as the student would undo it.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/refactoring"

block legacy
at refactoring
put "$HERE/the-safety-net.md" report.py
run python3 report.py
run 'python3 report.py > approved.txt'

block characterise
put "$HERE/the-safety-net.md" test_report.py 1
run python3 -m unittest -v test_report.py
put "$HERE/the-safety-net.md" test_report.py 2
run python3 -m unittest -v test_report.py

block extract
put "$HERE/long-function.md" report.py
run python3 -m unittest test_report.py

block slip
put "$HERE/duplication.md" report.py
sed -i 's/{cents % 100:02d}/{cents % 100}/' report.py
run python3 test_report.py
put "$HERE/duplication.md" report.py
run python3 test_report.py

block primitive
put "$HERE/primitive-obsession.md" report.py
run python3 -m unittest -v

block clumps
put "$HERE/feature-envy-and-data-clumps.md" report.py
run python3 -m unittest

block switch
put "$HERE/switch-on-type.md" test_report.py
run python3 test_report.py -v
put "$HERE/switch-on-type.md" report.py
run python3 test_report.py -v
run 'python3 report.py | diff - approved.txt && echo identical'
exit 0
