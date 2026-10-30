#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. server.ts, backoff.ts,
# schedule.ts and retry.ts are taken from the lesson by lab/extract.py
# (retry.ts from its annotated example, joined as the copy button joins it).
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The lesson has the student run `node server.ts ...` in a second
#     terminal and stop it with Ctrl+C between runs. Here each one runs in
#     the background on port 8009 and is stopped by the script; "droppedlog"
#     prints what the server wrote to its terminal, under the command.
#   - The waits are real: the script sleeps them, so it takes about ten seconds.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/retry
LAB as 'rm -rf ~/planner/retry && mkdir -p ~/planner/retry'
put what-to-retry.md server.ts $P/server.ts
put what-to-retry.md backoff.ts $P/backoff.ts
put what-to-retry.md retry.ts $P/retry.ts
put backoff.md schedule.ts $P/schedule.ts

block classify
serve $P 8009 'node server.ts 503 503'
run $P 'node retry.ts'
unserve
serve $P 8009 'node server.ts 400'
run $P 'node retry.ts'
unserve

block schedule
run $P 'node schedule.ts'

block retryafter
serve $P 8009 'node server.ts 429'
run $P 'node retry.ts'
unserve

block giveup
serve $P 8009 'node server.ts 503 503 503 503 503'
run $P 'node retry.ts'
unserve

block dropped
serve $P 8009 'node server.ts drop'
run $P 'node retry.ts'
run $P 'curl -s http://127.0.0.1:8009/sessions'

block droppedlog
printf 'ana@dev:~/planner/retry$ node server.ts drop\n'
cat "$LOGF"
unserve
