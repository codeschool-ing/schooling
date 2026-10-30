#!/usr/bin/env bash
# The terminal session quoted in lesson 15 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. field.ts is taken from
# the lesson by lab/extract.py. Its data are made by its own seeded generator,
# so every run prints the same table.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block field
put percentiles-not-averages.md field.ts $P/field.ts
run $P 'node field.ts'
