#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner (package.json,
# better-sqlite3 and data.ts). store.ts and app.ts are taken from
# the-local-write.md by lab/extract.py.
#
# STAGED: nothing beyond lab.sh. The folder ~/planner/offline is removed first,
# so planner.db starts empty.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/offline
LAB as 'rm -rf ~/planner/offline && mkdir -p ~/planner/offline'
put the-local-write.md store.ts $P/store.ts
put the-local-write.md app.ts $P/app.ts

block local
run $P 'node app.ts seed'
run $P 'node app.ts add s7 guitar 2026-10-23 25'
run $P 'node app.ts week 2026-10-19'

block sync
run $P 'node app.ts add s8 statistics 2026-10-24 300'
run $P 'node app.ts sync offline'
run $P 'node app.ts sync online'
run $P 'node app.ts week 2026-10-19'
