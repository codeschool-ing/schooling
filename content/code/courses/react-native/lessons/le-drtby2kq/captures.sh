#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 3 left, and leaves it for lesson 5.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `expo export`'s report goes to /dev/null; `npx expo serve` runs in the
#     background, as from a second terminal.
#   - Jest's stack trace for the failing test is cut to the line that names
#     the error with grep, as the lesson says.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-3x78m0wv
P=/home/ana/planner

put react-in-brief.md src/Greeting.tsx $P/src/Greeting.tsx
put text-rules.md __tests__/bare-string.test.tsx $P/__tests__/bare-string.test.tsx
block barestring
run $P 'npx jest bare-string 2>&1 | grep -E "Invariant|Tests:"'
quiet $P 'rm __tests__/bare-string.test.tsx'

put pressable.md src/CourseRow.tsx $P/src/CourseRow.tsx
put the-screen.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
put the-screen.md App.tsx $P/App.tsx
put the-screen.md __tests__/PlanScreen.test.tsx $P/__tests__/PlanScreen.test.tsx
block test
run $P 'npx tsc --noEmit'
run $P 'npm test'

quiet $P 'npx expo export --platform web'
serve $P 8082 'npx expo serve --port 8082'
block look
run $P "node look.mjs 'http://localhost:8082/?today=2026-10-21'"
run $P "node look.mjs 'http://localhost:8082/?today=2026-10-21' --click 'Guitar 2 sessions planned'"
unserve
