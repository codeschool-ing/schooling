#!/usr/bin/env bash
# The terminal session quoted in lesson 12 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. reporter.ts, app.ts and
# collector.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - collector.ts is started in the background, where the lesson tells the
#     student to start it in a second terminal.
#   - The report's install identifier, time and file name come from the
#     moment of the capture and differ on every run; the prose quotes none.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'cd ~/planner && rm -rf crashes collected.log install-id'

put a-reporter-you-can-read.md reporter.ts $P/reporter.ts
put a-reporter-you-can-read.md app.ts $P/app.ts
put a-reporter-you-can-read.md collector.ts $P/collector.ts
serve $P 4312 'node collector.ts'

block crash
run $P 'node app.ts statistics; echo "exit status $?"'
run $P 'cat crashes/*.json'
run $P 'node app.ts week'
run $P 'ls crashes; cat collected.log'
unserve
