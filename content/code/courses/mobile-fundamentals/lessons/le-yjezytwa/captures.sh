#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of mobile-fundamentals, as a script
# that produces them. The output is not committed: lab/fill.py pastes each
# block into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner holds lesson 1's planner.ts and package.json, taken out of
#     lesson 1's the-planner.md, as the student has them by now.
#   - prefs.ts and store.ts are taken out of this lesson's sections by
#     lab/extract.py, so the program each transcript ran is the one the
#     lesson prints.
#   - better-sqlite3 13.0.3 comes from the npm registry, through the
#     recording machine's gateway (lab.sh says how npm is pointed at it).
#   - `ls -l` prints the recording's own dates and times; the lesson quotes
#     only the sizes.
#
# The times in `ls -l` are the clock when the capture ran (30 October 2026),
# so a run on another day differs in those columns and nowhere else.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md planner.ts $P/planner.ts
put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put preferences.md prefs.ts $P/prefs.ts
put a-database.md store.ts $P/store.ts

block prefs
run $P 'node prefs.ts'
run $P 'node prefs.ts theme dark'
run $P 'node prefs.ts tab courses'
run $P 'cat prefs.json'
run $P 'ls -l prefs*'

block install
run $P 'npm install -E better-sqlite3@13.0.3'
run $P 'cat package.json'

block store
run $P 'node store.ts 2026-10-21'
run $P 'ls -l planner.db'

block again
run $P 'node store.ts 2026-10-21'
run $P 'ls -l'
