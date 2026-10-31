#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 15 left, and leaves it for lesson 17.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `expo prebuild`'s report goes to /dev/null.
#   - Nothing here delivers a notification: there is no phone, and the
#     sections that would need one say so in italics.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-1dt202c2
P=/home/ana/planner

block install
run $P 'npx expo install expo-notifications'
block declare
run $P 'npx expo prebuild --clean --no-install > /dev/null 2>&1'
run $P 'grep uses-permission node_modules/expo-notifications/android/src/main/AndroidManifest.xml'
run $P 'grep -A1 aps-environment ios/Studyplanner/Studyplanner.entitlements'

put local-reminders.md src/reminders.ts $P/src/reminders.ts
put switch.md src/RemindersSwitch.tsx $P/src/RemindersSwitch.tsx
put switch.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
put handlers.md App.tsx $P/App.tsx
put handlers.md src/navigation.tsx $P/src/navigation.tsx
block jestfail
run $P 'npx tsc --noEmit'
run $P 'npx jest App.test --forceExit 2>&1 | grep -A2 "●"'
put tested.md jest.setup.ts $P/jest.setup.ts
put tested.md __tests__/reminders.test.ts $P/__tests__/reminders.test.ts
put tested.md __tests__/tap.test.tsx $P/__tests__/tap.test.tsx
block tests
run $P 'npx jest reminders tap --verbose --forceExit 2>&1 | grep -E "✓|Tests:"'
run $P 'npx jest --forceExit 2>&1 | tail -5'
