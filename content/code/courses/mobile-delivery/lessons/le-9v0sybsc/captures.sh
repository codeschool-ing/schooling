#!/usr/bin/env bash
# The terminal session quoted in lesson 8 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. rollout.ts is taken from
# the lesson by lab/extract.py. The installs and their crashes are invented by
# the program itself, from a hash, so every run prints the same lines; the
# figure in "Deciding to halt" draws those lines' numbers.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block rollout
put deciding-to-halt.md rollout.ts $P/rollout.ts
run $P 'node rollout.ts'
