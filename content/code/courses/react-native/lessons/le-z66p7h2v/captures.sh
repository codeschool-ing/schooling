#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 11 left, and leaves it for lesson 13.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The planner's server and `serve` run in the background, as from two
#     more terminals. Each `frames.mjs` run changes the server's plan, which
#     is why the second starts where the first ended.
#   - `expo export`'s report goes to /dev/null. Jest runs with --forceExit,
#     as lesson 11 says.
#   - The browser's window is Playwright's default, 1280 wide, so the bar's
#     full width is 1232.
#   - reanimated.md's WeekBarReanimated.tsx is put into the project, checked
#     by `tsc` and removed again: the section says it was compiled, not run.
#   - Before the swipe, both servers are stopped and started again, which is
#     what gestures.md asks for: the plan starts from courses.json again.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-7zejv1f3
P=/home/ana/planner

put animated.md src/WeekBar.tsx $P/src/WeekBar.tsx
put animated.md __tests__/WeekBar.test.tsx $P/__tests__/WeekBar.test.tsx
block test
run $P 'npx tsc --noEmit'
run $P 'npx jest WeekBar --forceExit'

put measured.md frames.mjs $P/frames.mjs
serve $P 8008 'node server.mjs'
quiet $P 'EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'npx -y serve@14.2.6 --single -l 8082 dist'
block frames
run $P "node frames.mjs 'http://localhost:8082/?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'"
block reduced
run $P "node frames.mjs 'http://localhost:8082/?today=2026-10-21' 'Mark 30 min on 2026-10-22 done' --reduced"
unserve

block install
run $P 'npx expo install react-native-reanimated react-native-worklets react-native-gesture-handler'
put reanimated.md src/WeekBarReanimated.tsx $P/src/WeekBarReanimated.tsx
LAB as "$LID" "cd $P && npx tsc --noEmit" || { echo "WeekBarReanimated.tsx does not compile" >&2; exit 1; }
rm $H/planner/src/WeekBarReanimated.tsx

put gestures.md App.tsx $P/App.tsx
put gestures.md src/swipe.ts $P/src/swipe.ts
put gestures.md src/SwipeRow.tsx $P/src/SwipeRow.tsx
put gestures.md src/SessionList.tsx $P/src/SessionList.tsx
block jestfail
run $P 'npx jest SessionList --forceExit 2>&1 | head -8'
put gestures.md jest.setup.ts $P/jest.setup.ts
put gestures.md __tests__/swipe.test.ts $P/__tests__/swipe.test.ts
block jestpass
run $P 'npx tsc --noEmit'
run $P 'npx jest --forceExit'

put gestures.md swipe.mjs $P/swipe.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'npx -y serve@14.2.6 --single -l 8082 dist'
block swipe
run $P "node swipe.mjs 'http://localhost:8082/week?today=2026-10-21' s4 60"
run $P "node swipe.mjs 'http://localhost:8082/week?today=2026-10-21' s4 150"
block serverlog
served 8008
unserve
