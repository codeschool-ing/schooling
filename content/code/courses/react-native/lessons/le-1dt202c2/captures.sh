#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 14 left, and leaves it for lesson 16.
# Every file it writes is taken from this lesson's .md by lab/extract.py; a
# file written twice is put from its first listing and then its second.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - app.json is changed with `jsonedit`, the edit declaring.md asks for in
#     an editor; `expo prebuild`'s and `expo export`'s reports go to /dev/null.
#   - The planner's server and static.mjs run in the background, as from two
#     more terminals, as in lesson 14.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-azm92k0h
P=/home/ana/planner

block install
run $P 'npx expo install expo-location'
jsonedit $P app.json 'c.expo.plugins = c.expo.plugins.filter((p) => p !== "expo-location" && p[0] !== "expo-location"); c.expo.plugins.push(["expo-location", { locationWhenInUsePermission: "If you turn it on, the planner notes roughly where you study, to about a kilometre.", locationAlwaysAndWhenInUsePermission: false, locationAlwaysPermission: false, locationFullAccuracyPermission: false, motionUsagePermission: false, isIosReducedAccuracyByDefault: true }])'
block declare
run $P 'grep -A10 "\"expo-location\"" app.json'
run $P 'npx expo prebuild --clean --no-install > /dev/null 2>&1'
run $P 'grep LOCATION android/app/src/main/AndroidManifest.xml'
run $P 'grep -A1 NSLocation ios/Studyplanner/Info.plist'

put place.md src/place.ts $P/src/place.ts
put place.md src/journal.ts $P/src/journal.ts
put switch.md src/planState.tsx $P/src/planState.tsx
put switch.md src/WeekScreen.tsx $P/src/WeekScreen.tsx
put tested.md __tests__/journal.test.ts $P/__tests__/journal.test.ts 1
block oldrow
run $P 'npx tsc --noEmit'
run $P 'npx jest journal --forceExit 2>&1 | grep -E "●|has no column|Tests:"'
put tested.md __tests__/journal.test.ts $P/__tests__/journal.test.ts 2
put tested.md __tests__/place.test.tsx $P/__tests__/place.test.tsx
block tests
run $P 'npx jest journal place --verbose --forceExit 2>&1 | grep -E "✓|Tests:"'
run $P 'npx jest --forceExit 2>&1 | tail -5'

put browser.md where.mjs $P/where.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'node static.mjs dist 8082'
block where
run $P "node where.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'"
run $P "node where.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 30 min on 2026-10-22 done' --deny"
unserve
