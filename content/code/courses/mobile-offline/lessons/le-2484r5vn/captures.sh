#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. Every program is taken
# from the lesson's own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The lesson has the student run `node server.ts` in a second terminal.
#     Here it runs in the background on port 8008, and "serverlog" prints what
#     it wrote to its terminal by the end of "up", under the command that
#     started it, less the `GET /` serve sends to see that it answers.
#   - ~/planner/outbox is removed first, so planner.db starts empty.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/outbox
LAB as 'rm -rf ~/planner/outbox && mkdir -p ~/planner/outbox'
put the-outbox.md store.ts $P/store.ts
put the-outbox.md app.ts $P/app.ts
put draining.md server.ts $P/server.ts
put draining.md drain.ts $P/drain.ts
put coalescing.md compact.ts $P/compact.ts

block queue
run $P 'node app.ts add s7 guitar 2026-10-23 25'
run $P 'node app.ts minutes s7 30'
run $P 'node app.ts add s8 statistics 2026-10-24 40'
run $P 'node app.ts outbox'

block down
run $P 'node drain.ts'

serve $P 8008 'node server.ts'
block up
run $P 'node drain.ts'
run $P 'curl -s http://127.0.0.1:8008/sessions'
cp "$LOGF" /tmp/mo-l08-serverlog

block compact
run $P 'node app.ts minutes s7 35'
run $P 'node app.ts minutes s7 40'
run $P 'node app.ts add s9 spanish 2026-10-25 30'
run $P 'node app.ts remove s9'
run $P 'node app.ts add s10 guitar 2026-10-26 20'
run $P 'node app.ts outbox'
run $P 'node compact.ts'
run $P 'node app.ts outbox'
run $P 'node drain.ts'

block poison
run $P 'node app.ts add s11 statistics 2026-10-27 300'
run $P 'node app.ts minutes s11 200'
run $P 'node app.ts add s12 spanish 2026-10-28 30'
run $P 'node drain.ts'
run $P 'node app.ts outbox'

block revive
run $P 'node app.ts revive s11'
run $P 'node app.ts outbox'
run $P 'node drain.ts'
run $P 'curl -s http://127.0.0.1:8008/sessions'

block serverlog
printf 'ana@dev:~/planner/outbox$ node server.ts\n'
grep -v '^GET /$' /tmp/mo-l08-serverlog
