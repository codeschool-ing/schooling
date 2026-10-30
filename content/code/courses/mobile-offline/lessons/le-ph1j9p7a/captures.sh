#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. lww.ts is taken from
# last-write-wins.md by lab/extract.py, so the program each transcript ran is
# the one the lesson prints.
#
# STAGED: nothing beyond what lab.sh says for every lesson. The "morning" is
# written into the program, so every run prints the same lines.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/lww
LAB as 'rm -rf ~/planner/lww && mkdir -p ~/planner/lww'
put last-write-wins.md lww.ts $D/lww.ts

block lww
run $D 'node lww.ts device-clock'

block skew
run $D 'node lww.ts device-clock phone=120'

block server
run $D 'node lww.ts server-clock'
