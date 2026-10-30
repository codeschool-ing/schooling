#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of mobile-fundamentals, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds
# it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner as lesson 1 leaves it: package.json, planner.ts and week.ts
#     taken out of lesson 1's the-planner.md by lab/extract.py, in a git
#     repository with lesson 1's commit (made quietly, with a fixed date).
#     Lesson 2's screen-term.ts is not needed here and is not staged.
#   - choose.ts is taken out of the-matrix.md, so the file the transcripts ran
#     is the one the lesson prints.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
L1=../le-55jmmbqr/the-planner.md

for f in package.json planner.ts week.ts; do put $L1 $f $P/$f; done
quiet $P "export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'; git init -q && git add . && git commit -q -m 'The planner core, as lesson 1 gives it'"
put the-matrix.md choose.ts $P/choose.ts

block default
run $P 'node choose.ts'

block time
run $P 'node choose.ts time=5'

block performance
run $P 'node choose.ts performance=5'

block typo
run $P 'node choose.ts speed=5'

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-22 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-22 09:00:00 -0300'"
run $P 'git add choose.ts'
run $P 'git commit -q -m "A decision matrix for the planner team"'
RUNENV=
