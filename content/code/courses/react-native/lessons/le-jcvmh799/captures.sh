#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 6 left, and leaves it for lesson 8.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `expo export`'s report goes to /dev/null; `npx expo serve` runs in the
#     background, as from a second terminal.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-px42k9np
P=/home/ana/planner

put why-not-map.md __tests__/virtual.test.tsx $P/__tests__/virtual.test.tsx
block virtual
run $P 'npx jest virtual'
put keys.md __tests__/keys.test.tsx $P/__tests__/keys.test.tsx
block keys
run $P 'npx jest keys'
put flatlist.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
block flatlisttest
run $P 'npx tsc --noEmit'
run $P 'npx jest PlanScreen App'
put sectionlist.md src/SessionList.tsx $P/src/SessionList.tsx
put sectionlist.md __tests__/SessionList.test.tsx $P/__tests__/SessionList.test.tsx
block sections
run $P 'npx jest SessionList'
quiet $P 'npx expo export --platform web'
serve $P 8082 'npx expo serve --port 8082'
block look
run $P "node look.mjs 'http://localhost:8082/?today=2026-10-21'"
unserve
