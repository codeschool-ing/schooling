#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of design-patterns, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   bash captures.sh
#
# Each program is lifted out of the lesson's own .md by ../../lab.sh, so the
# file that runs here is the block the student copies. What is STAGED rather
# than typed:
#   - the machine: a stock Ubuntu 24.04 as ../../lab.sh describes, whose only
#     Python is the system's 3.12.3, as `python3`;
#   - in "sync-and-async-projection", the worker that applies events later is
#     called by hand inside lag.py, so the stale window prints the same lines
#     on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
rm -rf "$HOME/patterns/cqrs"

block one-model-strains
at cqrs
put "$HERE/one-model-strains.md" strained.py
run python3 strained.py

block cqs
put "$HERE/cqs.md" cqs.py
run python3 cqs.py

block commands-and-handlers
put "$HERE/commands-and-handlers.md" commands.py
run python3 commands.py

block read-models
put "$HERE/read-models.md" read_model.py
run python3 read_model.py

block sync-and-async-projection
put "$HERE/sync-and-async-projection.md" lag.py
run python3 lag.py

block when-not-to
run wc -l strained.py commands.py read_model.py
exit 0
