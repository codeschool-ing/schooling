#!/usr/bin/env bash
# The terminal session quoted in lesson 9 of mobile-fundamentals, as a script
# that produces it. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it. STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner with lesson 1's package.json, taken out of lesson 1's
#     the-planner.md. insets.ts imports nothing from the planner.
#   - insets.ts is taken out of this lesson's computed.md.
# The screen sizes, insets and keyboard height are examples written into the
# program, not device measurements, and the output is the same on every run.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put computed.md insets.ts $P/insets.ts

block insets
run $P 'node insets.ts'
