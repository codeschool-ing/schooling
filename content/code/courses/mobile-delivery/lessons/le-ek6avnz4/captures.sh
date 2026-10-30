#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of mobile-delivery, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. config.json,
# config-server.ts, client.ts and rollout-share.ts are taken from the lesson
# by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - config-server.ts runs in the background, where the lesson tells the
#     student to start it in a second terminal; "the server is down" is the
#     capture stopping it.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'rm -f ~/planner/config-cache.json'
put remote-config.md config.json $P/config.json
put remote-config.md config-server.ts $P/config-server.ts
put remote-config.md client.ts $P/client.ts
put feature-flags.md rollout-share.ts $P/rollout-share.ts
serve $P 4319 'node config-server.ts'

block flags
run $P 'node rollout-share.ts'
run $P 'node client.ts 1.6.0 i009; node client.ts 1.6.0 i042'
run $P "sed -i 's/\"killed\": false/\"killed\": true/' config.json && node client.ts 1.6.0 i009"
LAB as "cd ~/planner && sed -i 's/\"killed\": true/\"killed\": false/' config.json"

block versions
run $P 'node client.ts 1.5.0; node client.ts 1.5.2; node client.ts 1.6.0'
unserve
run $P 'node client.ts 1.5.0'
run $P 'rm config-cache.json; node client.ts 1.5.0'
