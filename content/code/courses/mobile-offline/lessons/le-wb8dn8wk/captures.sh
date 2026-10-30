#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. bg.ts is taken from
# a-sync-that-can-stop.md by lab/extract.py. Only that section is run: the
# Kotlin, Swift and React Native listings of the lesson need a device, and the
# lesson marks each of them as not run.
#
# STAGED: nothing beyond what lab.sh says for every lesson. The "system" that
# grants steps and kills the process is the program's two arguments, as the
# lesson explains; background.db starts absent.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/background
LAB as 'rm -rf ~/planner/background && mkdir -p ~/planner/background'
put a-sync-that-can-stop.md bg.ts $D/bg.ts

block runs
run $D 'node bg.ts 4'
run $D 'node bg.ts 3 2; echo "exit status $?"'
run $D 'node bg.ts 10'
run $D 'node bg.ts 10'
