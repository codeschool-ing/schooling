#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of mobile-fundamentals, as a script
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
#     The files lessons 2 to 4 add are not needed here and are not staged.
#   - restore.ts is taken out of round-trip.md, so the file the transcripts
#     ran is the one the lesson prints.
#   - "use" kills its own process with SIGKILL; the shell's report of that is
#     part of what the lesson reads, so the command is followed by an echo of
#     its exit status in the same line.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
L1=../le-55jmmbqr/the-planner.md

for f in package.json planner.ts week.ts; do put $L1 $f $P/$f; done
quiet $P "export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'; git init -q && git add . && git commit -q -m 'The planner core, as lesson 1 gives it'"
put round-trip.md restore.ts $P/restore.ts

block fresh
run $P 'node restore.ts open'

block use
run $P 'node restore.ts use; echo "exit status $?"'

block saved
run $P 'cat saved-state.json; echo'

block restored
run $P 'node restore.ts open'

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-24 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-24 09:00:00 -0300'"
run $P 'echo saved-state.json >> .gitignore'
run $P 'git add .gitignore restore.ts'
run $P 'git commit -q -m "Saved UI state, restored after a kill"'
run $P 'git status --short'
RUNENV=

block sizes
run $P 'node restore.ts sizes'
