#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of mobile-offline, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner (data.ts is imported by
# the server). server.ts, store.ts, device.ts and resync.ts are taken from the
# lesson by lab/extract.py (resync.ts from its annotated example).
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The lesson has the student run `node server.ts` in a second terminal
#     and restart it with Ctrl+C. Here it runs in the background on port
#     8012, and is restarted by the script where the lesson says to.
#   - "Another phone" is a curl against the same server, and so is the
#     server forgetting its tombstones, which a real server does on a schedule.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/resync
U=http://127.0.0.1:8012
LAB as 'rm -rf ~/planner/resync && mkdir -p ~/planner/resync'
put when-deltas-fail.md server.ts $P/server.ts
put the-snapshot.md store.ts $P/store.ts
put the-snapshot.md resync.ts $P/resync.ts
put the-snapshot.md device.ts $P/device.ts

block gone
serve $P 8012 'node server.ts'
run $P "curl -s -o /dev/null -X DELETE $U/sessions/s3"
run $P "curl -s -X POST $U/forget; echo"
run $P "curl -s -w ' %{http_code}\n' '$U/changes?after=6'"
unserve

block swap
serve $P 8012 'node server.ts'
run $P 'node device.ts pull'
run $P "curl -s -o /dev/null -X DELETE $U/sessions/s3"
run $P "curl -s -o /dev/null -X POST $U/forget"
run $P 'node device.ts pull'
run $P 'node device.ts show'
run $P 'ls'
unserve

block pending
serve $P 8012 'node server.ts'
run $P 'rm planner.db'
run $P 'node device.ts pull'
run $P 'node device.ts add s9 spanish 2026-10-27 30'
run $P "curl -s -o /dev/null -X DELETE $U/sessions/s3"
run $P "curl -s -o /dev/null -X POST $U/forget"
run $P 'node device.ts pull'
run $P 'node device.ts show'
unserve

block cost
serve $P 8012 'node server.ts'
run $P 'rm planner.db'
run $P "curl -s -X POST '$U/fill?n=2000'; echo"
run $P 'node device.ts pull'
run $P "curl -s -o /dev/null -X DELETE $U/sessions/s3"
run $P "curl -s -o /dev/null -X POST $U/forget"
run $P 'node device.ts pull'
run $P "stat -c '%s bytes' planner.db"
unserve
