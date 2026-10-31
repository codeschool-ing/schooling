#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 10 left, and leaves it for lesson 12.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The planner's server and `serve` run in the background, as from two
#     more terminals; `served 8008` shows what the server printed.
#   - `expo export`'s report goes to /dev/null.
#   - Jest runs with --forceExit: the app's query client keeps timers that
#     would otherwise hold a run open on the recording machine.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-e224f7yh
P=/home/ana/planner

put validation.md src/validate.ts $P/src/validate.ts
put validation.md __tests__/validate.test.ts $P/__tests__/validate.test.ts
block validate
run $P 'npx jest validate --forceExit'

put the-form.md src/AddSessionScreen.tsx $P/src/AddSessionScreen.tsx
put the-form.md src/theme.ts $P/src/theme.ts
put the-form.md src/navigation.tsx $P/src/navigation.tsx
put the-form.md src/CourseScreen.tsx $P/src/CourseScreen.tsx
put against-the-server.md server.mjs $P/server.mjs
put against-the-server.md src/api.ts $P/src/api.ts
put against-the-server.md src/planState.tsx $P/src/planState.tsx
put leaving.md __tests__/AddSession.test.tsx $P/__tests__/AddSession.test.tsx
block formtest
run $P 'npx tsc --noEmit'
run $P 'npx jest AddSession --forceExit'

serve $P 8008 'node server.mjs'
block curl
run $P "curl -s -X POST localhost:8008/sessions -H 'content-type: application/json' -d '{\"course\":\"guitar\",\"date\":\"2026-10-23\",\"minutes\":999}'; echo"
quiet $P 'EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'npx -y serve@14.2.6 --single -l 8082 dist'
U=http://localhost:8082/course/guitar
block web
run $P "node look.mjs '$U' --click 'Add a session' --fill Date=23/10/2026 --fill Minutes=25 --click 'Save session'"
run $P "node look.mjs '$U' --click 'Add a session' --fill Date=2026-10-23 --fill Minutes=25 --click 'Save session' --wait 500"
block serverlog
served 8008
unserve
