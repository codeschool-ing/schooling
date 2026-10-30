#!/usr/bin/env bash
# The terminal session quoted in lesson 7 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. tracks.ts is taken from
# the lesson by lab/extract.py. Nothing is staged beyond lab.sh.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block tracks
put one-build-promoted.md tracks.ts $P/tracks.ts
run $P 'node tracks.ts'
