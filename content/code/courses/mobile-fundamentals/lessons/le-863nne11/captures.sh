#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of mobile-fundamentals, as a script
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
#     are taken out of lesson 1's the-planner.md by lab/extract.py, and the
#     folder is a git repository with lesson 1's commit in it (made quietly,
#     with a fixed date, because lesson 1 shows that step).
#   - screen-web.ts and screen-term.ts are taken out of logic-shares.md, so
#     the files the transcripts ran are the ones the lesson prints.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
L1=../le-55jmmbqr/the-planner.md

for f in package.json planner.ts week.ts; do put $L1 $f $P/$f; done
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'"
quiet $P "$RUNENV; git init -q && git add . && git commit -q -m 'The planner core, as lesson 1 gives it'"

block week
run $P 'node week.ts'

put logic-shares.md screen-web.ts $P/screen-web.ts
block web
run $P 'node screen-web.ts'

put logic-shares.md screen-term.ts $P/screen-term.ts
block term
run $P 'node screen-term.ts'

block keep
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 10:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 10:00:00 -0300'"
run $P 'rm screen-web.ts'
run $P 'git add screen-term.ts'
run $P 'git commit -q -m "A terminal screen over the same core"'
run $P 'git log --oneline'
RUNENV=
