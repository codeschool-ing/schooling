#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of mobile-offline, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner (data.ts is imported by
# the server). server.ts, pull.ts and clocks.ts are taken from the lesson by
# lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The lesson has the student run `node server.ts` in a second terminal
#     and restart it with Ctrl+C. Here it runs in the background on port
#     8011, and is restarted by the script where the lesson says to.
#   - "Another phone" is a curl against the same server.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/delta
LAB as 'rm -rf ~/planner/delta && mkdir -p ~/planner/delta'
put pulling-everything.md server.ts $P/server.ts
put pulling-everything.md pull.ts $P/pull.ts
put timestamps-and-clocks.md clocks.ts $P/clocks.ts
S7='{"course":"guitar","date":"2026-10-23","minutes":25}'

block all
serve $P 8011 'node server.ts'
run $P "curl -s -X POST 'http://127.0.0.1:8011/fill?n=2000'; echo"
run $P 'node pull.ts all'
run $P 'node pull.ts all'

block delta
run $P 'rm planner.db'
run $P 'node pull.ts delta'
run $P 'node pull.ts delta'
run $P "curl -s -o /dev/null -X PUT -d '$S7' 'http://127.0.0.1:8011/sessions/s7?stamp=2026-10-21T10:00:00Z'"
run $P 'node pull.ts delta'
unserve

block clocks
serve $P 8011 'node server.ts'
run $P 'node clocks.ts'
unserve

block deletes
serve $P 8011 'node server.ts'
run $P 'rm planner.db'
run $P 'node pull.ts delta'
run $P "curl -s -o /dev/null -X DELETE 'http://127.0.0.1:8011/sessions/s3?stamp=2026-10-21T10:30:00Z'"
run $P "curl -s 'http://127.0.0.1:8011/changed-since?t=2026-10-21T10:00:00Z'; echo"
run $P 'node pull.ts delta'
unserve
