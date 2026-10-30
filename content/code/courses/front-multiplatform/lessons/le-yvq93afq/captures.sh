#!/usr/bin/env bash
# The terminal session quoted in lesson 6 of front-multiplatform, as a script
# that produces it; lab/fill.py pastes it into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the planner lesson 5 left. ceiling.mjs is taken from
# measuring.md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `npm run preview` runs in the background, as the lesson has the student
#     run it in a terminal of its own.
#   - The times are this machine's, on the day; a rerun prints others.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 5
P=/home/ana/planner
put measuring.md ceiling.mjs $P/ceiling.mjs
quiet $P 'npm run build'
serve $P 4173 'npm run preview'
U="'http://localhost:4173/?today=2026-10-21'"
block ceiling
run $P "node ceiling.mjs $U 50"
run $P "node ceiling.mjs $U 500"
run $P "node ceiling.mjs $U 5000"
run $P "node ceiling.mjs $U 5000 1"
unserve
RUNENV="export GIT_AUTHOR_DATE='2026-10-22 15:00:00 -0300' GIT_COMMITTER_DATE='2026-10-22 15:00:00 -0300'"
quiet $P 'git add ceiling.mjs && git commit -q -m "Measure a tap with thousands of sessions"'
save_as 6
