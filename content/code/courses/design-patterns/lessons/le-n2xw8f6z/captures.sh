#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - every file is written before the run that uses it, in the order the
#     sections show them; nothing is edited by hand.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/solid-2"
at solid-2

block isp
put "$HERE/isp.md" catalogue.py
put "$HERE/isp.md" fake_kiosk.py
run python3 fake_kiosk.py

block fat-interfaces
put "$HERE/fat-interfaces.md" items.py
run python3 items.py

block roles
put "$HERE/roles-as-protocols.md" roles.py
run python3 roles.py

block dip-in-code
put "$HERE/dip-in-code.md" notices.py
put "$HERE/dip-in-code.md" adapters.py
put "$HERE/dip-in-code.md" main.py
run python3 main.py
run grep -n import notices.py adapters.py main.py
put "$HERE/dip-in-code.md" test_notices.py
run python3 -m unittest -v test_notices.py

block ports
put "$HERE/ports-and-adapters.md" cli.py
run python3 cli.py 2026-03-25

block overdone
put "$HERE/solid-overdone.md" overdone.py
put "$HERE/solid-overdone.md" plain.py
run python3 overdone.py
run python3 plain.py
run wc -l overdone.py plain.py
exit 0
