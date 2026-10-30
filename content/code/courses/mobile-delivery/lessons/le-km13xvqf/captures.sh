#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of mobile-delivery, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. seen.json, support.ts,
# the two contracts, contract.ts, api-additive.ts, api-rename.ts and
# sunset-server.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - sunset-server.ts runs in the background, where the lesson tells the
#     student to start it in a second terminal, and is restarted for the
#     second day the same way.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
put the-app-that-never-updates.md seen.json $P/seen.json
put the-app-that-never-updates.md support.ts $P/support.ts
put a-contract-test.md 1.3.1.json $P/contracts/1.3.1.json
put a-contract-test.md 1.5.2.json $P/contracts/1.5.2.json
put a-contract-test.md contract.ts $P/contract.ts
put a-contract-test.md api-additive.ts $P/api-additive.ts
put a-contract-test.md api-rename.ts $P/api-rename.ts
put retiring-an-endpoint.md sunset-server.ts $P/sunset-server.ts

block support
run $P 'node support.ts 1.5.1'
run $P 'node support.ts 1.4.0 | tail -n 1'

block contract
run $P 'node contract.ts api-additive.ts; echo "exit status $?"'
run $P 'node contract.ts api-rename.ts; echo "exit status $?"'

block sunset
serve $P 4320 'node sunset-server.ts 2026-10-30'
run $P "curl -si http://127.0.0.1:4320/v1/sessions | grep -iE '^(HTTP|sunset|link)'"
unserve
serve $P 4320 'node sunset-server.ts 2027-04-01'
run $P "curl -si http://127.0.0.1:4320/v1/sessions | grep -iE '^HTTP'; curl -s http://127.0.0.1:4320/v1/sessions; echo"
