#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - nothing else. flood.py and strategies.py run on a simulated clock, and
#     blocking.py prints only what its bounded queue guarantees, so every
#     line below is the same on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/reactive"

block push-and-pull
at reactive
put "$HERE/push-and-pull.md" pull_push.py
run python3 pull_push.py

block observables
put "$HERE/observables.md" observable.py
run python3 observable.py

block operators
put "$HERE/operators.md" operators.py
run python3 operators.py

block hot-and-cold
put "$HERE/hot-and-cold.md" hot_cold.py
run python3 hot_cold.py

block backpressure
put "$HERE/backpressure.md" flood.py
run python3 flood.py
put "$HERE/backpressure.md" blocking.py
run python3 blocking.py

block strategies
put "$HERE/strategies.md" strategies.py
run python3 strategies.py
exit 0
