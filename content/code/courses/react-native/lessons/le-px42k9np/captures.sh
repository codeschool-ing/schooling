#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 5 left, and leaves it for lesson 7.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The bundles are exported after the screen imports ./savedWhere, which the
#     lesson asks for in the section after the one that shows them.
#   - `expo export`'s reports go to /dev/null; the `grep -c` after each shows
#     what went into the bundles.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-1n9wxxdv
P=/home/ana/planner

put platform-select.md src/card.ts $P/src/card.ts
put file-extensions.md src/savedWhere.ios.ts $P/src/savedWhere.ios.ts
put file-extensions.md src/savedWhere.android.ts $P/src/savedWhere.android.ts
put file-extensions.md src/savedWhere.ts $P/src/savedWhere.ts
block install
run $P 'npm install -E react-native-safe-area-context@5.10.1'
put safe-areas.md App.tsx $P/App.tsx
put safe-areas.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
put safe-areas.md jest.setup.ts $P/jest.setup.ts
put safe-areas.md __tests__/PlanScreen.test.tsx $P/__tests__/PlanScreen.test.tsx
quiet $P 'npm pkg set "jest.setupFiles[0]=./jest.setup.ts"'

block bundles
run $P 'npx expo export --platform android --output-dir out-android > /dev/null 2>&1'
run $P 'npx expo export --platform web --output-dir out-web > /dev/null 2>&1'
run $P 'grep -c "this Android device" out-android/_expo/static/js/android/*.hbc'
run $P 'grep -c "this iPhone" out-android/_expo/static/js/android/*.hbc'
run $P 'grep -c "in this browser" out-web/_expo/static/js/web/*.js'
run $P 'rm -r out-android out-web'

put each-platform.md __tests__/platform.test.ts $P/__tests__/platform.test.ts
block universal
run $P "npx jest --config '{\"preset\":\"jest-expo/universal\"}' platform"
block test
run $P 'npx tsc --noEmit'
run $P 'npm test'
