#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - in shared.py and actor.py, a time.sleep between the check and the act,
#     written into the program and said so in the prose, which makes the race
#     in shared.py happen on every run instead of once in a long while.
# The programs print nothing that depends on which thread ran first, so every
# line below is the same on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/actors"

block the-shared-state-problem
at actors
put "$HERE/the-shared-state-problem.md" shared.py
run python3 shared.py

block building-one
put "$HERE/building-one.md" actor.py
run python3 actor.py

block tell-and-ask
put "$HERE/tell-and-ask.md" ask.py
run python3 ask.py

block supervision
put "$HERE/supervision.md" supervision.py
run python3 supervision.py

block location-transparency
put "$HERE/location-transparency.md" location.py
run python3 location.py
exit 0
