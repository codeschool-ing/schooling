#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - the date: shell.py is given 2026-03-20 on its command line, as the
#     lesson tells the student to do, so the run does not depend on the clock.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/functional"

block pure
at functional
put "$HERE/pure-functions.md" pure.py
run python3 pure.py

block frozen
put "$HERE/immutability.md" frozen.py
run python3 frozen.py

block shell
put "$HERE/side-effects-at-the-edges.md" core.py
put "$HERE/side-effects-at-the-edges.md" shell.py
put "$HERE/side-effects-at-the-edges.md" test_core.py
run python3 shell.py 2026-03-20
run cat outbox.txt
run python3 -m unittest -v test_core.py

block hof
put "$HERE/higher-order-functions.md" hof.py
run python3 hof.py

block mfr
put "$HERE/map-filter-reduce.md" mfr.py
run python3 mfr.py

block result
put "$HERE/errors-as-values.md" result.py
run python3 result.py
exit 0
