#!/usr/bin/env bash
# The terminal session quoted in lesson 16 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner, with better-sqlite3.
# analytics.ts, simulate.ts and funnel.ts are taken from the lesson by
# lab/extract.py. The events are made by simulate.ts's own seeded generator,
# so every run prints the same funnel, and the figure draws its numbers.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'rm -f ~/planner/events.db'

block funnel
put a-funnel.md analytics.ts $P/analytics.ts
put a-funnel.md simulate.ts $P/simulate.ts
put a-funnel.md funnel.ts $P/funnel.ts
run $P 'node simulate.ts'
run $P 'node funnel.ts'
