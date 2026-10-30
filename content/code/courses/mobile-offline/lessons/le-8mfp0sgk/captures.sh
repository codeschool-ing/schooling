#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner, and starts from no
# ~/planner/model. Every program is taken from the lesson by lab/extract.py.
#
# STAGED: nothing beyond what lab.sh says for every lesson. ids.ts prints the
# length of each UUID rather than the UUID, so the transcript repeats;
# window.ts makes its rows from lesson 3's fixed seed.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/model
LAB as 'rm -rf ~/planner/model ~/planner/model-try && mkdir -p ~/planner/model'
put denormalise.md denorm.ts $P/denorm.ts
put ids-on-the-device.md ids.ts $P/ids.ts
put what-the-device-holds.md window.ts $P/window.ts

block denorm
run $P 'node denorm.ts app'
run $P 'node denorm.ts triggers'
block ids
run $P 'node ids.ts'
block window
run $P 'node window.ts 2026-10-21 12'
run $P 'node window.ts 2026-10-21 52'
