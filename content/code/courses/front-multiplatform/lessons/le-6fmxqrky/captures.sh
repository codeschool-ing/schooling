#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 6 left, and from no ~/planner-native. App.tsx is
# taken from the-rules-come-along.md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - create-expo-app's report goes to /dev/null in the transcript: it ends
#     with emoji and draws a spinner the interface has no glyph for. So does `expo export`'s,
#     which draws with U+203A.
#   - `npx expo serve` runs in the background, as from a second terminal.
#   - EXPO_OFFLINE=1 is in the environment (lab.sh says why); nothing quoted
#     here prints anything different for it.
#   - The commit carries a fixed date.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 6
LAB as 'rm -rf ~/planner-native'
N=/home/ana/planner-native

block create
run /home/ana 'npx create-expo-app@5.0.0 planner-native --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1'
run /home/ana 'cd planner-native'
run $N 'ls'

block install
run $N 'npm install -E expo@58.0.17 expo-status-bar@58.0.4 react@19.3.0 react-native@0.88.0 react-dom@19.3.0 react-native-web@0.21.4 @expo/metro-runtime@58.0.15'
run $N 'npm install -E -D typescript@6.0.3 @types/react@19.3.0 playwright@1.63.0'
run $N "grep -A12 '\"dependencies\"' package.json"

block copy
run $N 'mkdir src'
run $N 'cp ../planner/src/planner.ts ../planner/public/courses.json src/'
run $N 'cp ../planner/look.mjs .'
run $N 'cmp ../planner/src/planner.ts src/planner.ts && echo identical'

put the-rules-come-along.md App.tsx $N/App.tsx
block tsc
run $N 'npx tsc --noEmit'

block export
run $N 'npx expo export --platform web > /dev/null'
run $N 'ls dist'
serve $N 8082 'npx expo serve --port 8082'
block look
U="'http://localhost:8082/?today=2026-10-21'"
run $N "node look.mjs $U"
run $N "node look.mjs $U --click 'Spanish A2' --click 'Mark done'"
unserve

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-22 17:00:00 -0300' GIT_COMMITTER_DATE='2026-10-22 17:00:00 -0300'"
run $N 'git add . && git commit -q -m "The planner, drawn with React Native" && git log --oneline'
save_as 7
