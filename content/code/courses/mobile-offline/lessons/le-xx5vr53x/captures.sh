#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of mobile-offline, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. server.ts, buy.ts and
# send.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The lesson has the student run `node server.ts ...` in a second
#     terminal and stop it with Ctrl+C between runs. Here each one runs in
#     the background on port 8010 and is stopped by the script.
#   - The keys buy.ts makes are random and it does not print them, so the
#     transcripts repeat.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/idempotency
LAB as 'rm -rf ~/planner/idempotency && mkdir -p ~/planner/idempotency'
put the-payment.md server.ts $P/server.ts
put the-payment.md buy.ts $P/buy.ts
put what-the-server-keeps.md send.ts $P/send.ts

block twice
serve $P 8010 'node server.ts drop'
run $P 'node buy.ts'
run $P 'curl -s http://127.0.0.1:8010/purchases'
unserve

block once
serve $P 8010 'node server.ts drop'
run $P 'node buy.ts key'
run $P 'curl -s http://127.0.0.1:8010/purchases'
unserve

block cases
serve $P 8010 'node server.ts ok ok ok ok slow'
run $P 'node send.ts ana k-1 statistics 4900'
run $P 'node send.ts ana k-1 statistics 4900'
run $P 'node send.ts ana k-1 guitar 3900'
run $P 'node send.ts bia k-1 statistics 4900'

block race
RUNENV="cd $P"   # the first command of the line runs in the background, before `cd && ...` applies
run $P 'node send.ts ana k-2 guitar 3900 & node send.ts ana k-2 guitar 3900; wait'
RUNENV=
unserve

block put
serve $P 8010 'node server.ts'
S='{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}'
run $P "curl -s -X PUT -H 'x-user: ana' -d '$S' http://127.0.0.1:8010/sessions/s7"
run $P "curl -s -X PUT -H 'x-user: ana' -d '$S' http://127.0.0.1:8010/sessions/s7"
run $P 'curl -s http://127.0.0.1:8010/sessions'
unserve
