#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 8 left, and leaves it for lesson 10.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-0wwe77xz
P=/home/ana/planner

put reducer.md src/planState.tsx $P/src/planState.tsx
put reducer.md __tests__/reducer.test.ts $P/__tests__/reducer.test.ts
block reducer
run $P 'npx jest reducer'
put context.md App.tsx $P/App.tsx
put shared-screens.md src/SessionList.tsx $P/src/SessionList.tsx
put shared-screens.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
put shared-screens.md src/WeekScreen.tsx $P/src/WeekScreen.tsx
put shared-screens.md src/CourseScreen.tsx $P/src/CourseScreen.tsx
put shared-screens.md __tests__/done.test.tsx $P/__tests__/done.test.tsx
put shared-screens.md __tests__/navigation.test.tsx $P/__tests__/navigation.test.tsx
put shared-screens.md __tests__/PlanScreen.test.tsx $P/__tests__/PlanScreen.test.tsx
block shared
run $P 'npx tsc --noEmit'
run $P 'npx jest done navigation PlanScreen App'
block install
run $P 'npm install -E zustand@5.0.16'
put store.md __tests__/renders.test.tsx $P/__tests__/renders.test.tsx
block renders
run $P 'npx jest renders'
