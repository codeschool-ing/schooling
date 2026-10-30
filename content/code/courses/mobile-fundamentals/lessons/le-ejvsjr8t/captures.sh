#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of mobile-fundamentals, as a script
# that produces them. The output is not committed: lab/fill.py pastes each
# block into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it. STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner with lesson 1's package.json and planner.ts, taken out of
#     lesson 1's the-planner.md (frames.ts imports the Session type from it).
#     The files of lessons 2 to 5 are not there, and nothing here lists the
#     folder, so their absence shows nowhere.
#   - budget.ts and frames.ts are taken out of this lesson's the-budget.md and
#     measured.md, so the program each transcript ran is the one printed.
#
# THE TIMINGS ARE REAL AND ARE NOT DETERMINISTIC. frames.ts measures the clock
# of the machine it runs on. This script was run once, its output was pasted
# into the lesson, and the prose quotes those numbers and says that they vary
# from run to run and from machine to machine. Running it again gives other
# numbers, and fill.py --check is held against the saved output of that run.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, 4 processor cores,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

for f in package.json planner.ts; do put ../le-55jmmbqr/the-planner.md $f $P/$f; done
put the-budget.md budget.ts $P/budget.ts
put measured.md frames.ts $P/frames.ts

block budget
run $P 'node budget.ts'

block idle
run $P 'node frames.ts idle'

block main
run $P 'node frames.ts main'

block worker
run $P 'node frames.ts worker'
