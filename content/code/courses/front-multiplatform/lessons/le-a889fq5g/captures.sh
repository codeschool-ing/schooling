#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 7 left. src/plan.tsx and the three screens are
# taken from the-screens.md, and axe.mjs from accessibility.md, by
# lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `npx expo export` goes to /dev/null, as in lesson 7; `npx expo serve`
#     runs in the background.
#   - "axe-fail" changes one colour in app/course/[id].tsx with the sed it
#     prints and puts it back with git checkout.
#   - The commit carries a fixed date.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 7
N=/home/ana/planner-native

block router
run $N 'npx expo install expo-router react-native-screens react-native-safe-area-context expo-linking expo-constants'
block entry
run $N 'npm install -E expo-router@58.0.26 react-native-screens@4.30.0 react-native-safe-area-context@5.10.1 expo-linking@58.0.14 expo-constants@58.0.13 > /dev/null'
run $N 'npm pkg set main=expo-router/entry'
run $N 'git rm -q App.tsx index.ts'
run $N 'grep -E "\"main\"|expo-router" package.json'

put the-screens.md src/plan.tsx $N/src/plan.tsx
put the-screens.md app/_layout.tsx $N/app/_layout.tsx
put the-screens.md app/index.tsx $N/app/index.tsx
put the-screens.md 'app/course/[id].tsx' "$N/app/course/[id].tsx"
block build
run $N 'npx tsc --noEmit'
run $N 'npx expo export --platform web > /dev/null'
run $N 'ls dist'

serve $N 8082 'npx expo serve --port 8082'
U="'http://localhost:8082/?today=2026-10-21'"
block home
run $N "node look.mjs $U --wait 1000"
block course
run $N "node look.mjs $U --click Statistics --fill Date=2026-10-23 --fill Minutes=25 --click 'Add session'"
run $N "node look.mjs $U --click Statistics --fill Date=23/10 --fill Minutes=25 --click 'Add session' | tail -n 3"

block axe-install
run $N 'npm install -E -D @axe-core/playwright@4.14.0'
put accessibility.md axe.mjs $N/axe.mjs
block axe
run $N "node axe.mjs $U"
run $N "node axe.mjs $U --click Statistics"
unserve
block axe-fail
run $N "sed -i 's/action: { color: \"#0a58ca\"/action: { color: \"#7aa7e8\"/' 'app/course/[id].tsx'"
run $N 'npx expo export --platform web > /dev/null'
serve $N 8082 'npx expo serve --port 8082'
run $N "node axe.mjs $U --click Statistics"
unserve
quiet $N "git checkout 'app/course/[id].tsx' && npx expo export --platform web"

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 09:00:00 -0300'"
run $N 'git add . && git commit -q -m "Two screens, a form, and axe" && git log --oneline -1'
save_as 8
