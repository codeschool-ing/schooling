#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of mobile-delivery, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and ~/planner as lessons 1 to 5 leave it:
# listing.ts with the five problems of lesson 4 unfixed, privacy.ts with its
# inventory, and expiry.ts with lesson 2's certificates. release.json,
# review-notes.txt and preflight.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "preflight-fixed" edits release.json the way the prose says, with a node
#     one-liner the lesson does not print.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block preflight
put a-gate-before-submitting.md release.json $P/release.json
put a-gate-before-submitting.md review-notes.txt $P/review-notes.txt
put a-gate-before-submitting.md preflight.ts $P/preflight.ts
run $P 'node preflight.ts; echo "exit status $?"'

block preflight-fixed
LAB as "cd ~/planner && node -e 'const fs=require(\"fs\");const r=JSON.parse(fs.readFileSync(\"release.json\"));r.apiBase=\"https://api.planner.example\";r.debugMenu=false;fs.writeFileSync(\"release.json\",JSON.stringify(r,null,2)+\"\\n\")'"
run $P 'node preflight.ts'
