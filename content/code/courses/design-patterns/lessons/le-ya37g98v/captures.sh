#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - every store lives in memory, so each program starts from an empty store
#     and prints the same lines on every run;
#   - in "eventual-consistency", lag.py runs a real worker thread that sleeps
#     50 ms per event; the reads that come before it are microseconds after
#     the write, so the stale lines are what an ordinary machine prints.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/events"

block state-versus-history
at events
put "$HERE/state-versus-history.md" state_only.py
run python3 state_only.py

block the-event-store
put "$HERE/the-event-store.md" store.py
run python3 store.py

block folding
put "$HERE/folding.md" fold.py
run python3 fold.py

block projections
put "$HERE/projections.md" projections.py
run python3 projections.py

block snapshots
put "$HERE/snapshots.md" snapshot.py
run python3 snapshot.py

block eventual-consistency
put "$HERE/eventual-consistency.md" lag.py
run python3 lag.py

block versioning-events
put "$HERE/versioning-events.md" upcast.py
run python3 upcast.py
exit 0
