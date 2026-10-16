#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`, on a laptop with four cores;
#   - nothing else. The timings, the lost-update counts and which desk gives up
#     in the deadlock come from the run, and the prose says which of them move
#     from one run to the next.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/concurrency"

block models
at concurrency
put "$HERE/concurrency-and-parallelism.md" models.py
run python3 models.py

block race
put "$HERE/race-conditions.md" race.py
run python3 race.py
run python3 race.py
put "$HERE/race-conditions.md" plus_equals.py
run python3 plus_equals.py

block locks
put "$HERE/locks.md" locks.py
run python3 locks.py
put "$HERE/locks.md" deadlock.py 1
run python3 deadlock.py
put "$HERE/locks.md" deadlock.py 2
run python3 deadlock.py

block singleton
put "$HERE/singleton-under-threads.md" catalogue.py 1
run python3 catalogue.py
put "$HERE/singleton-under-threads.md" catalogue.py 2
run python3 catalogue.py

block observer
put "$HERE/observer-under-threads.md" observers.py 1
run python3 observers.py
put "$HERE/observer-under-threads.md" observers.py 2
run python3 observers.py

block immutability
put "$HERE/immutability-helps.md" rules.py
run python3 rules.py
exit 0
