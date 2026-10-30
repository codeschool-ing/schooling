#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of mobile-fundamentals, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds
# it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner holds lesson 1's package.json, taken out of lesson 1's
#     the-planner.md; neither program here imports anything else.
#   - version.ts and rollout.ts are taken out of versions.md and
#     after-publishing.md.
#   - Nothing here talks to a store. No store account exists on this machine,
#     and the lesson says so at its top.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put versions.md version.ts $P/version.ts
put after-publishing.md rollout.ts $P/rollout.ts

block version
run $P 'node version.ts'

block rollout
run $P 'node rollout.ts'
