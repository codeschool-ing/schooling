#!/usr/bin/env bash
# The terminal session quoted in lesson 12 of mobile-fundamentals, as a script
# that produces it. lab/fill.py pastes the block into the fence that holds it,
# and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as lab.sh
# installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner with lesson 1's package.json, taken out of lesson 1.
#   - permission.ts and ask.ts, taken out of this lesson's the-model.md, so
#     the program the transcript ran is the one the lesson prints.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put the-model.md permission.ts $P/permission.ts
put the-model.md ask.ts $P/ask.ts

block ask
run $P 'node ask.ts'
