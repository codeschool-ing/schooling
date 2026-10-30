#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner, and starts from no
# ~/planner/prefs. kv.ts, settings.ts, torn.ts and grow.ts are taken from the
# lesson by lab/extract.py, so the program each transcript ran is the one it
# prints.
#
# STAGED: nothing beyond what lab.sh says for every lesson. torn.ts stops
# itself halfway through a write; the lesson says that is what it does.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/prefs
LAB as 'rm -rf ~/planner/prefs ~/planner/prefs-try && mkdir -p ~/planner/prefs'
put a-kv-store.md kv.ts $P/kv.ts
put a-kv-store.md settings.ts $P/settings.ts
put the-torn-write.md torn.ts $P/torn.ts
put what-not-to-store.md grow.ts $P/grow.ts

block settings
run $P 'node settings.ts set theme dark'
run $P 'node settings.ts set dailyGoal 45'
run $P 'node settings.ts get theme'
run $P 'node settings.ts get dailyGoal'
run $P 'node settings.ts'
run $P 'cat settings.json'

block torn
run $P 'node torn.ts in-place'
run $P 'node torn.ts rename'
run $P 'ls'

block grow
run $P 'node grow.ts'
LAB as 'rm -f ~/planner/prefs/grow.json'
