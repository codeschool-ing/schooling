#!/usr/bin/env bash
# The terminal session quoted in lesson 15 of mobile-fundamentals, as a script
# that produces it. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner holds lesson 1's package.json, taken out of lesson 1's
#     the-planner.md, so that batch.ts runs as a module, as it does for the
#     student. batch.ts is taken out of a-day-in-numbers.md by lab/extract.py.
#   - batch.ts reads no clock and no device: it is a model, and prints the same
#     numbers on every run.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put a-day-in-numbers.md batch.ts $P/batch.ts

block batch
run $P 'node batch.ts'
