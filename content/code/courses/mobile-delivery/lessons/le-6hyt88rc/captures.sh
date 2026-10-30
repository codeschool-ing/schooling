#!/usr/bin/env bash
# The terminal session quoted in lesson 14 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. hang.ts is taken from
# the lesson by lab/extract.py. The seconds it prints are whole seconds of the
# recording machine's clock; a slower machine may print one more.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'rm -f ~/planner/hang-report.txt'

block hang
put a-watchdog-you-can-watch.md hang.ts $P/hang.ts
run $P 'node hang.ts blocking'
run $P 'node hang.ts free'
run $P 'cat hang-report.txt'
