#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 17 left, and leaves it for lesson 19.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `expo export`'s reports go to /dev/null, and the three Android exports
#     are deleted after the env block, as the section says to.
#   - The position whereis.mjs is given is read from crash.mjs's output by
#     this script, as the student copies it from the screen.
#   - The planner's server and static.mjs run in the background.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-0xa1kkx9
P=/home/ana/planner

block bundles
run $P 'npx expo export --platform android --dev --output-dir dist-dev > /dev/null 2>&1'
run $P 'npx expo export --platform android --output-dir dist-release > /dev/null 2>&1'
run $P 'du -h dist-dev/_expo/static/js/android/* dist-release/_expo/static/js/android/*'
run $P "grep -a -c 'Text strings must be rendered within a <Text>' dist-dev/_expo/static/js/android/* dist-release/_expo/static/js/android/*"
block env
run $P "grep -a -o 'http://localhost:8008' dist-release/_expo/static/js/android/*"
run $P 'EXPO_PUBLIC_API_URL=https://planner.example.org npx expo export --platform android --output-dir dist-env > /dev/null 2>&1'
run $P "grep -a -o 'https://planner.example.org\|http://localhost:8008' dist-env/_expo/static/js/android/*"
quiet $P 'rm -rf dist-dev dist-release dist-env'

put boundary.md src/ErrorBoundary.tsx $P/src/ErrorBoundary.tsx
put boundary.md App.tsx $P/App.tsx
put boundary.md __tests__/ErrorBoundary.test.tsx $P/__tests__/ErrorBoundary.test.tsx
block boundarytest
run $P 'npx tsc --noEmit'
run $P 'npx jest ErrorBoundary --verbose --forceExit 2>&1 | grep -E "✓|Tests:"'

put source-maps.md crash.mjs $P/crash.mjs
put source-maps.md whereis.mjs $P/whereis.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && npx expo export --platform web --source-maps'
serve $P 8082 'node static.mjs dist 8082'
block crash
run $P "node crash.mjs 'http://localhost:8082/?today=2026-10-21'"
POS=$(LAB as "$LID" "cd $P && node crash.mjs 'http://localhost:8082/?today=2026-10-21'" | grep -o 'index-[0-9a-f]*\.js:[0-9]*:[0-9]*')
[ -n "$POS" ] || { echo "crash.mjs printed no position" >&2; exit 1; }
block whereis
run $P "node whereis.mjs dist $POS"
run $P 'sed -n 30p src/planner.ts'

put at-the-door.md src/api.ts $P/src/api.ts
put at-the-door.md __tests__/api.test.ts $P/__tests__/api.test.ts
block door
run $P 'npx jest api.test --verbose --forceExit 2>&1 | grep -E "✓|Tests:"'
quiet $P 'rm -rf dist && npx expo export --platform web --source-maps'
run $P "node crash.mjs 'http://localhost:8082/?today=2026-10-21'"
run $P 'npx jest --forceExit 2>&1 | tail -5'
unserve
