#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. crdt.ts, merges.ts,
# yjs.ts and costs.ts are taken from the lesson by lab/extract.py.
#
# STAGED: nothing beyond what lab.sh says for every lesson. "install" adds yjs
# to ~/planner as the lesson has the student do; on a second run npm finds it
# already there and prints a shorter line. The Yjs client ids and the CRDT tags
# are fixed in the programs, so the byte counts repeat.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/crdt
LAB as 'rm -rf ~/planner/crdt && mkdir -p ~/planner/crdt'
put counters-and-sets.md crdt.ts $D/crdt.ts
put counters-and-sets.md merges.ts $D/merges.ts
put yjs.md yjs.ts $D/yjs.ts
put libraries.md costs.ts $D/costs.ts

block install
run /home/ana/planner 'npm install -E yjs@13.6.33'
run /home/ana/planner 'cat package.json'

block merges
run $D 'node merges.ts'

block yjs
run $D 'node yjs.ts'

block same-field
run $D 'node yjs.ts same-field'

block costs
run $D 'node costs.ts'
run $D 'node costs.ts keep-history'
