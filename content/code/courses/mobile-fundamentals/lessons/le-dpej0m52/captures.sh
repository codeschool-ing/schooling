#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of mobile-fundamentals, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds
# it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as lab.sh
# installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner as lesson 1 leaves it: package.json, planner.ts and week.ts,
#     taken out of lesson 1's the-planner.md, committed with lesson 1's message
#     and the same fixed date. The lessons between add their own commits, so
#     the lesson shows the commit and not the log, whose hashes would differ.
#   - backstack.ts (the-model.md) and taps.ts (the-run.md), taken out of this
#     lesson, so the program the transcript ran is the one the lesson prints.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

for f in package.json planner.ts week.ts; do put ../le-55jmmbqr/the-planner.md $f $P/$f; done
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'"
quiet $P "$RUNENV; git init -q && git add . && git commit -q -m 'The planner core, as lesson 1 gives it'"
put the-model.md backstack.ts $P/backstack.ts
put the-run.md taps.ts $P/taps.ts

block run
run $P 'node taps.ts'

block git
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 10:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 10:00:00 -0300'"
run $P 'git add backstack.ts taps.ts'
run $P 'git commit -q -m "Two tabs, each with its own back stack"'
RUNENV=
