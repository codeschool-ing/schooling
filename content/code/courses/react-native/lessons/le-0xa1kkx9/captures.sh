#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 16 left, and leaves it for lesson 18.
# Every file it writes is taken from this lesson's .md by lab/extract.py; a
# file written twice is put from its first listing and then its second.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - create-expo-module's, `expo prebuild`'s, Gradle's and `expo export`'s
#     reports go to /dev/null where a block does not quote them.
#   - The Android build is for arm64-v8a only, as in lesson 3.
#   - The Swift file is written and never compiled: there is no Mac.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-9y1met5p
P=/home/ana/planner
M=$P/modules/week-start

block create
run $P "npx create-expo-module@58.0.3 week-start --local --barrel --name WeekStart --package org.example.weekstart --platform apple android web --features Function --description 'The first day of the week' > /dev/null 2>&1"
run $P 'find modules -type f | sort'

put native-code.md modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt $M/android/src/main/java/org/example/weekstart/WeekStartModule.kt
put native-code.md modules/week-start/ios/WeekStartModule.swift $M/ios/WeekStartModule.swift
put javascript-side.md modules/week-start/src/WeekStartModule.ts $M/src/WeekStartModule.ts
put javascript-side.md modules/week-start/src/WeekStartModule.web.ts $M/src/WeekStartModule.web.ts
put javascript-side.md modules/week-start/src/WeekStart.types.ts $M/src/WeekStart.types.ts
put javascript-side.md src/PlanScreen.tsx $P/src/PlanScreen.tsx
block jestfail
run $P 'npx tsc --noEmit'
run $P 'npx jest PlanScreen --forceExit 2>&1 | grep -A2 "●"'
put jest.md jest.setup.ts $P/jest.setup.ts
put jest.md __tests__/weekStart.test.tsx $P/__tests__/weekStart.test.tsx
block jestpass
run $P 'npx jest weekStart PlanScreen --verbose --forceExit 2>&1 | grep -E "✓|Tests:"'

put jvm-tests.md modules/week-start/android/build.gradle $M/android/build.gradle
put jvm-tests.md modules/week-start/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt $M/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt 1
block kotlinfail
run $P 'npx expo prebuild --platform android --clean --no-install > /dev/null 2>&1'
run $P/android './gradlew :week-start:testDebugUnitTest --console=plain 2>&1 | grep -E "FAILED|AssertionError|tests completed"'
put jvm-tests.md modules/week-start/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt $M/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt 2
block kotlinpass
run $P/android './gradlew :week-start:testDebugUnitTest --console=plain 2>&1 | grep -E "FAILED|BUILD"'

block apk
run $P/android './gradlew :app:assembleDebug -PreactNativeArchitectures=arm64-v8a -q > /dev/null 2>&1'
run $P/android 'du -h app/build/outputs/apk/debug/app-debug.apk'
run $P/android "unzip -p app/build/outputs/apk/debug/app-debug.apk 'classes*.dex' | grep -a -o 'org/example/weekstart/[A-Za-z]*' | sort -u"

put browser.md note.mjs $P/note.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'node static.mjs dist 8082'
block web
run $P "node note.mjs 'http://localhost:8082/?today=2026-10-21' pt-BR"
run $P "node note.mjs 'http://localhost:8082/?today=2026-10-21' en-GB"
run $P "node note.mjs 'http://localhost:8082/?today=2026-10-21' pt-PT"
unserve
