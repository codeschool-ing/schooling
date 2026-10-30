#!/usr/bin/env bash
# The terminal session quoted in lesson 9 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. history.json and
# version.ts are taken from the lesson by lab/extract.py. Nothing is staged.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block version
put deriving-the-code.md history.json $P/history.json
put deriving-the-code.md version.ts $P/version.ts
run $P 'node version.ts 1.5.0 3'
run $P 'node version.ts 1.4.1 1'
run $P 'node version.ts 1.5.0 2'
run $P 'node version.ts 1.5.100 1'
