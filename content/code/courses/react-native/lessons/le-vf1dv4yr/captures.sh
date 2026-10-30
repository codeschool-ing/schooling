#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 12 left, and leaves it for lesson 14.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - app.json is changed with `jsonedit`, which is the edit declaring.md asks
#     for in an editor; `expo prebuild`'s, Gradle's and `expo export`'s
#     reports go to /dev/null.
#   - The one-line change browser.md asks for, `alt` to `aria-label`, is made
#     with sed.
#   - The planner's server and `serve` run in the background, as from two more
#     terminals, as in lesson 10.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-z66p7h2v
P=/home/ana/planner

block install
run $P 'npx expo install expo-image-picker expo-file-system'

jsonedit $P app.json 'c.expo.plugins = [["expo-image-picker", { cameraPermission: "The planner uses the camera to photograph your notes for a course.", photosPermission: false, microphonePermission: false }]]'
block declare
run $P 'grep -A9 "\"plugins\"" app.json'
run $P 'npx expo prebuild --clean --no-install > /dev/null 2>&1'
run $P 'grep uses-permission android/app/src/main/AndroidManifest.xml'
run $P 'grep -A1 UsageDescription ios/Studyplanner/Info.plist'
block merged
run $P/android './gradlew :app:processDebugMainManifest -q > /dev/null 2>&1'
run $P/android "tr '\\n' ' ' < app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml | grep -o '<uses-permission *android:name=\"[^\"]*\"' | cut -d'\"' -f2 | sort"

put picker.md src/NotesPhoto.tsx $P/src/NotesPhoto.tsx
put picker.md src/CourseScreen.tsx $P/src/CourseScreen.tsx
put files.md src/keepPhoto.ts $P/src/keepPhoto.ts
put files.md src/keepPhoto.web.ts $P/src/keepPhoto.web.ts
put tested.md __tests__/NotesPhoto.test.tsx $P/__tests__/NotesPhoto.test.tsx
block tests
run $P 'npx tsc --noEmit'
run $P 'npx jest NotesPhoto --forceExit'

put browser.md pick.mjs $P/pick.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'npx -y serve@14.2.6 --single -l 8082 dist'
block alt
run $P "node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' assets/icon.png"

LAB as "$LID" "cd $P && sed -i 's|<Image source={{ uri }} alt=|<Image source={{ uri }} aria-label=|' src/NotesPhoto.tsx"
grep -q 'aria-label="Your photo' $H/planner/src/NotesPhoto.tsx || { echo "the alt edit did not apply" >&2; exit 1; }
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
block web
run $P "grep -n 'aria-label=\"Your photo' src/NotesPhoto.tsx"
run $P 'npx jest NotesPhoto --forceExit 2>&1 | tail -5'
run $P "node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' assets/icon.png"
run $P "node pick.mjs http://localhost:8082/course/guitar 'Take a photo' assets/icon.png"
unserve
