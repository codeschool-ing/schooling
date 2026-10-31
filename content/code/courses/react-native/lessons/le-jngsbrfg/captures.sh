#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 18 left, and leaves it for lesson 20.
# Every file it writes is taken from this lesson's .md by lab/extract.py; a
# file written twice is put from its first listing and then its second.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `expo export`'s report goes to /dev/null.
#   - The planner's server and static.mjs run in the background.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-rfg3y4xj
P=/home/ana/planner

put re-renders.md src/SessionRow.tsx $P/src/SessionRow.tsx 1
put re-renders.md src/SessionList.tsx $P/src/SessionList.tsx
put re-renders.md __tests__/rowRenders.test.tsx $P/__tests__/rowRenders.test.tsx
block before
run $P 'npx tsc --noEmit'
run $P 'npx jest rowRenders --forceExit 2>&1 | grep -E "rendered again|Tests:"'
put re-renders.md src/SessionRow.tsx $P/src/SessionRow.tsx 2
block after
run $P 'npx jest rowRenders --forceExit 2>&1 | grep -E "rendered again|Tests:"'

put stable-callbacks.md src/planState.tsx $P/src/planState.tsx
put stable-callbacks.md src/WeekScreen.tsx $P/src/WeekScreen.tsx
put stable-callbacks.md src/CourseScreen.tsx $P/src/CourseScreen.tsx
block stable
run $P 'npx tsc --noEmit'
run $P 'npx jest --forceExit 2>&1 | tail -5'

block install
run $P 'npx expo install expo-image-manipulator'
put images.md src/shrink.ts $P/src/shrink.ts
put images.md src/NotesPhoto.tsx $P/src/NotesPhoto.tsx
put images.md big.mjs $P/big.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'node static.mjs dist 8082'
block shrink
run $P 'node big.mjs big.png'
run $P 'file big.png'
run $P "node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' big.png"
run $P "node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' assets/icon.png"
unserve

put bundle.md packages.mjs $P/packages.mjs
quiet $P 'rm -rf dist && npx expo export --platform web --source-maps'
block bundle1
run $P 'f=$(ls dist/_expo/static/js/web/index-*.js); npx -y source-map-explorer@2.5.3 $f $f.map --no-border-checks --json | node packages.mjs'
run $P "grep -n \"require('react-native-reanimated')\" node_modules/react-native-gesture-handler/lib/module/handlers/gestures/reanimatedWrapper.js"
put bundle.md src/GestureRoot.tsx $P/src/GestureRoot.tsx
put bundle.md src/GestureRoot.web.tsx $P/src/GestureRoot.web.tsx
put bundle.md App.tsx $P/App.tsx
put bundle.md src/SwipeRow.web.tsx $P/src/SwipeRow.web.tsx
quiet $P 'rm -rf dist && npx expo export --platform web --source-maps'
block bundle2
run $P 'f=$(ls dist/_expo/static/js/web/index-*.js); npx -y source-map-explorer@2.5.3 $f $f.map --no-border-checks --json | node packages.mjs'
run $P 'npx tsc --noEmit'
run $P 'npx jest --forceExit 2>&1 | tail -5'
