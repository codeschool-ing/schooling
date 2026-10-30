#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 7 left, and leaves it for lesson 9.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `expo export`'s report goes to /dev/null; `serve` runs in the
#     background, as from a second terminal, and its own output is not quoted.
#   - app.json's scheme is set by jsonedit, where the student uses an editor.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-jcvmh799
P=/home/ana/planner

block install
run $P 'npm install -E @react-navigation/native@7.5.1 @react-navigation/native-stack@7.21.0 @react-navigation/bottom-tabs@7.21.0 react-native-screens@4.30.1'
put stack-and-tabs.md src/navigation.tsx $P/src/navigation.tsx
put stack-and-tabs.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
put stack-and-tabs.md src/WeekScreen.tsx $P/src/WeekScreen.tsx
put stack-and-tabs.md App.tsx $P/App.tsx
put params.md src/CourseScreen.tsx $P/src/CourseScreen.tsx
put params.md __tests__/navigation.test.tsx $P/__tests__/navigation.test.tsx
put params.md __tests__/PlanScreen.test.tsx $P/__tests__/PlanScreen.test.tsx
jsonedit $P app.json 'c.expo.scheme="planner"'
block test
run $P 'npx tsc --noEmit'
run $P 'npx jest navigation PlanScreen App'

quiet $P 'npx expo export --platform web'
serve $P 8082 'npx -y serve@14.2.6 --single -l 8082 dist'
block links
run $P "node look.mjs 'http://localhost:8082/course/guitar?today=2026-10-21'"
run $P "node look.mjs 'http://localhost:8082/week?today=2026-10-21'"
run $P "node look.mjs 'http://localhost:8082/course/chemistry'"
unserve
