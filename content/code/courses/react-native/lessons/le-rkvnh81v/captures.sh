#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 20 left, and leaves it for lesson 22.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - app.json is changed with `jsonedit`, and the note's wording with sed,
#     which are the two edits runtime-version.md asks for in an editor.
#   - `expo export`'s report goes to /dev/null.
#   - Nothing here talks to Expo's servers: api.expo.dev refused the machine
#     that recorded this course, so no update was published.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-7yjyybqg
P=/home/ana/planner

block install
run $P 'npx expo install expo-updates'
block export
run $P 'npx expo export --platform android > /dev/null 2>&1'
run $P 'node -p "const m = require(\"./dist/metadata.json\").fileMetadata.android; [m.bundle, m.assets.length + \" assets\"].join(\"\\n\")"'
run $P 'du -sh dist'

jsonedit $P app.json 'c.expo.runtimeVersion = { policy: "fingerprint" }'
put runtime-version.md changed.mjs $P/changed.mjs
block fingerprint
run $P 'grep -A2 runtimeVersion app.json'
run $P 'npx @expo/fingerprint fingerprint:generate > before.json'
run $P 'node -p "require(\"./before.json\").hash"'
LAB as "$LID" "cd $P && sed -i \"s/the planner's weeks start on Monday/the planner counts its weeks from Monday/\" src/PlanScreen.tsx"
grep -q "counts its weeks" $H/planner/src/PlanScreen.tsx || { echo "the wording edit did not apply" >&2; exit 1; }
run $P 'grep -n "counts its weeks" src/PlanScreen.tsx'
run $P 'npx @expo/fingerprint fingerprint:generate > after-js.json'
run $P 'node -p "require(\"./after-js.json\").hash"'
block native
run $P 'npx expo install expo-haptics > /dev/null 2>&1'
run $P 'npx @expo/fingerprint fingerprint:generate > after-native.json'
run $P 'node -p "require(\"./after-native.json\").hash"'
run $P 'npx @expo/fingerprint fingerprint:diff before.json after-native.json | node changed.mjs'
run $P 'npm uninstall expo-haptics > /dev/null 2>&1'
run $P 'npx @expo/fingerprint fingerprint:generate | node -p "JSON.parse(require(\"fs\").readFileSync(0)).hash"'
block tests
run $P 'npx jest weekStart --forceExit 2>&1 | grep -E "Tests:"'
quiet $P 'rm -f before.json after-js.json after-native.json && rm -rf dist'
