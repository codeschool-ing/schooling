#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of mobile-fundamentals, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds
# it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner holds lesson 1's package.json and planner.ts, taken out of
#     lesson 1's the-planner.md, committed quietly as one commit with a fixed
#     date: the student's repository has lessons 2 to 17 in it as well, so the
#     git block shows only the newest commit, whose hash depends on what came
#     before it.
#   - tokens.ts and themes.ts are taken out of tokens.md.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

for f in package.json planner.ts; do put ../le-55jmmbqr/the-planner.md $f $P/$f; done
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'"
quiet $P "$RUNENV; git init -q && git add . && git commit -q -m 'The planner core, as lesson 1 gives it'"
for f in tokens.ts themes.ts; do put tokens.md $f $P/$f; done

block themes
run $P 'node themes.ts'
run $P 'node themes.ts dark'

block git
run $P 'git add tokens.ts themes.ts'
run $P 'git commit -q -m "Design tokens, and a theme for each platform"'
run $P 'git log --oneline -1'
RUNENV=
