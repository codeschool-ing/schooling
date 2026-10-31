#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 4 left, and leaves it for lesson 6.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `expo export`'s report goes to /dev/null; `npx expo serve` runs in the
#     background, as from a second terminal.
#   - app.json's userInterfaceStyle is changed by jsonedit, where the student
#     uses an editor.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-drtby2kq
P=/home/ana/planner

put flexbox.md src/WeekBar.tsx $P/src/WeekBar.tsx
put flexbox.md boxes.mjs $P/boxes.mjs
put dark-mode.md src/theme.ts $P/src/theme.ts
put the-styled-planner.md src/CourseRow.tsx $P/src/CourseRow.tsx
put the-styled-planner.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
put the-styled-planner.md __tests__/WeekBar.test.tsx $P/__tests__/WeekBar.test.tsx
jsonedit $P app.json 'c.expo.userInterfaceStyle="automatic"'

block test
run $P 'npx tsc --noEmit'
run $P 'npm test'

quiet $P 'npx expo export --platform web'
serve $P 8082 'npx expo serve --port 8082'
U="'http://localhost:8082/?today=2026-10-21'"
block boxes
run $P "node boxes.mjs $U"
block dark
run $P "node boxes.mjs $U --dark"
block tablet
run $P "node boxes.mjs $U 768 1024"
unserve
