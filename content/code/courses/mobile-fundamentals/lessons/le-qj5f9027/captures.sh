#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of mobile-fundamentals, as a script
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
#   - inventory.ts and declare.ts, taken out of this lesson's the-inventory.md.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

for f in package.json planner.ts week.ts; do put ../le-55jmmbqr/the-planner.md $f $P/$f; done
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'"
quiet $P "$RUNENV; git init -q && git add . && git commit -q -m 'The planner core, as lesson 1 gives it'"
put the-inventory.md inventory.ts $P/inventory.ts
put the-inventory.md declare.ts $P/declare.ts

block declare
run $P 'node declare.ts'

block git
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 11:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 11:00:00 -0300'"
run $P 'git add inventory.ts declare.ts'
run $P 'git commit -q -m "The planner'"'"'s data inventory, and what it declares"'
RUNENV=
