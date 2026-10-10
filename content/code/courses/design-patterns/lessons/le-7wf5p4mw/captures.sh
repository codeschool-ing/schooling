#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - desk.py and main.py each have two versions in the lesson, and each run
#     below extracts the version the prose has the student holding at that
#     point (the third argument of `put`).
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/solid-1"
at solid-1

block srp
put "$HERE/srp.md" desk.py 1
run python3 desk.py
put "$HERE/srp.md" desk.py 2
run python3 desk.py

block srp-in-code
put "$HERE/srp-in-code.md" report_service.py
run python3 report_service.py
put "$HERE/srp-in-code.md" report.py
run python3 report.py
put "$HERE/srp-in-code.md" csv_report.py
run python3 csv_report.py

block ocp
put "$HERE/ocp.md" by_kind.py
run python3 by_kind.py

block ocp-in-code
put "$HERE/ocp-in-code.md" policies.py
put "$HERE/ocp-in-code.md" charges.py
put "$HERE/ocp-in-code.md" main.py 1
run python3 main.py
put "$HERE/ocp-in-code.md" capped.py
put "$HERE/ocp-in-code.md" main.py 2
run python3 main.py

block lsp
put "$HERE/lsp.md" items.py
run python3 items.py

block lsp-violations
put "$HERE/lsp-violations.md" laptop.py
put "$HERE/lsp-violations.md" shapes.py
run python3 shapes.py
put "$HERE/lsp-violations.md" test_contract.py
run python3 -m unittest test_contract.py
exit 0
