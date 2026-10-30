#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. server.ts, merge3.ts,
# sync.ts, vclock.ts and clocks.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The lesson has the student run server.ts in a terminal of its own. Here it
#     runs in the background on port 8014, and is restarted before "merge" and
#     before "same-field", so s3 is back at version 1 each time, as the lesson
#     says. "server-start" runs it under `timeout 1` to show the line it prints.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/versions
LAB as 'rm -rf ~/planner/versions && mkdir -p ~/planner/versions'
put version-numbers.md server.ts $D/server.ts
put field-by-field.md merge3.ts $D/merge3.ts
put field-by-field.md sync.ts $D/sync.ts
put vector-clocks.md vclock.ts $D/vclock.ts
put vector-clocks.md clocks.ts $D/clocks.ts
U=http://localhost:8014/sessions/s3

block server-start
run $D 'timeout 1 node server.ts'

serve $D 8014 'node server.ts'
block versions
run $D "curl -s $U"
run $D "curl -s -X PUT $U -d '{\"course\":\"guitar\",\"date\":\"2026-10-21\",\"minutes\":20,\"done\":true,\"version\":1}' -w '%{http_code}\n'"
run $D "curl -s -X PUT $U -d '{\"course\":\"guitar\",\"date\":\"2026-10-21\",\"minutes\":30,\"done\":false,\"version\":1}' -w '%{http_code}\n'"
unserve

serve $D 8014 'node server.ts'
block merge
run $D "curl -s -X PUT $U -d '{\"course\":\"guitar\",\"date\":\"2026-10-21\",\"minutes\":20,\"done\":true,\"version\":1}' -w '%{http_code}\n'"
run $D 'node sync.ts minutes=30'
unserve

serve $D 8014 'node server.ts'
block same-field
run $D "curl -s -X PUT $U -d '{\"course\":\"guitar\",\"date\":\"2026-10-21\",\"minutes\":25,\"done\":false,\"version\":1}' -w '%{http_code}\n'"
run $D 'node sync.ts minutes=30'
unserve

block clocks
run $D 'node clocks.ts'
