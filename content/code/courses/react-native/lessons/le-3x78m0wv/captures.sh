#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js installed, and leaves ~/planner
# for lesson 4. Every file it puts there is taken from this lesson's .md by
# lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - create-expo-app's report, `expo export`'s and `expo prebuild`'s go to
#     /dev/null: each draws a spinner and characters the interface has no
#     glyph for. `ls` shows what they wrote.
#   - The development server and `npx expo serve` run in the background, as
#     from a second terminal; their own output is not quoted.
#   - The Android SDK and JDK 17 are lab.sh's, in the places this lesson's
#     commands put them; the transcript starts after they are installed.
#   - The three identifiers in app.json are set by jsonedit, where the student
#     uses an editor; the grep after it shows them.
#   - Gradle's first build downloads its own distribution and the libraries;
#     the transcript keeps the last lines, which are what the lesson reads.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block create
run /home/ana 'npx create-expo-app@5.0.0 planner --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1'
run /home/ana 'cd planner'
run $P 'ls'

block pin
run $P 'npm install -E expo@58.0.21 expo-status-bar@58.0.4 react@19.3.0 react-native@0.88.1'
run $P 'npm install -E react-dom@19.3.0 react-native-web@0.21.4 @expo/metro-runtime@58.0.15 expo-dev-client@58.0.17'
run $P 'npm install -E -D jest@30.5.2 jest-expo@58.0.13 @testing-library/react-native@14.1.0 @types/jest@30.0.0 playwright@1.63.0 typescript@6.0.3 @types/react@19.3.0'
block audit
run $P 'npm audit | grep "Will install" | sort -u'

put the-planner.md src/planner.ts $P/src/planner.ts
put the-planner.md src/courses.json $P/src/courses.json
put the-planner.md src/today.ts $P/src/today.ts
put the-planner.md App.tsx $P/App.tsx
block tsc
run $P 'npx tsc --noEmit'

block metro
serve $P 8081 'npx expo start --port 8081'
run $P 'curl -s localhost:8081/status; echo'
run $P "curl -s 'localhost:8081/index.bundle?platform=android&dev=true' -o dev.js"
run $P 'ls -l dev.js'
run $P 'grep -c "Study planner" dev.js'
run $P 'grep -o "This week" dev.js | head -1'
unserve
quiet $P 'rm dev.js'

put the-web-build.md look.mjs $P/look.mjs
block export
run $P 'npx expo export --platform web > /dev/null 2>&1'
run $P 'ls dist'
serve $P 8082 'npx expo serve --port 8082'
block look
run $P "node look.mjs 'http://localhost:8082/?today=2026-10-21'"
unserve

put tests.md __tests__/planner.test.ts $P/__tests__/planner.test.ts
put tests.md __tests__/App.test.tsx $P/__tests__/App.test.tsx
quiet $P "npm pkg set scripts.test=jest jest.preset=jest-expo"
block test
run $P 'npm pkg get scripts.test jest'
run $P 'npm test'

jsonedit $P app.json 'c.expo.name="Study planner";c.expo.android.package="org.example.planner";c.expo.ios.bundleIdentifier="org.example.planner"'
block prebuild
run $P 'grep -nE "\"(name|package|bundleIdentifier)\"" app.json'
run $P 'npx expo prebuild --platform android --no-install > /dev/null 2>&1'
run $P 'grep applicationId android/app/build.gradle'
block gradle
run $P 'cd android'
run $P/android './gradlew assembleDebug -PreactNativeArchitectures=arm64-v8a 2>&1 | tail -3'
block apk
run $P/android 'ls -lh app/build/outputs/apk/debug/'
run $P/android '~/Android/Sdk/build-tools/37.0.0/aapt2 dump badging app/build/outputs/apk/debug/app-debug.apk | grep -E "^(package|minSdkVersion|targetSdkVersion|application-label:|native-code)"'
run $P/android 'unzip -l app/build/outputs/apk/debug/app-debug.apk | grep -cE "index.android.bundle"'
run $P/android 'unzip -l app/build/outputs/apk/debug/app-debug.apk | grep -E "libhermes|libreactnative"'
