#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 9 left, and leaves it for lesson 11.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The planner's server and `serve` run in the background, as from two
#     more terminals. What the server printed is shown with `served 8008`,
#     which is the text that terminal shows, without a prompt.
#   - `expo export`'s report goes to /dev/null.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-rsb4qqmp
P=/home/ana/planner

block install
run $P 'npm install -E @tanstack/react-query@5.105.0 @react-native-community/netinfo@12.0.1'
put the-server.md server.mjs $P/server.mjs
put the-server.md src/api.ts $P/src/api.ts
serve $P 8008 'node server.mjs'
block curl
run $P 'curl -s localhost:8008/plan | head -c 150; echo'
run $P 'curl -s -i -X POST localhost:8008/sessions/s9/done | head -1'
run $P 'curl -s -i -X POST localhost:8008/sessions/s9/done | tail -1; echo'

put queries.md src/planState.tsx $P/src/planState.tsx
put queries.md App.tsx $P/App.tsx
put queries.md jest.setup.ts $P/jest.setup.ts
put queries.md test-utils.tsx $P/test-utils.tsx
put queries.md __tests__/App.test.tsx $P/__tests__/App.test.tsx
put queries.md __tests__/failure.test.tsx $P/__tests__/failure.test.tsx
put queries.md __tests__/navigation.test.tsx $P/__tests__/navigation.test.tsx
put queries.md __tests__/PlanScreen.test.tsx $P/__tests__/PlanScreen.test.tsx
block queries
run $P 'npx tsc --noEmit'
run $P 'npx jest App failure navigation PlanScreen'
put mutations.md __tests__/done.test.tsx $P/__tests__/done.test.tsx
block mutations
run $P 'npx jest done'

quiet $P 'EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'npx -y serve@14.2.6 --single -l 8082 dist'
block live
run $P "node look.mjs 'http://localhost:8082/?today=2026-10-21'"
run $P "node look.mjs 'http://localhost:8082/week?today=2026-10-21' --click 'Mark 20 min on 2026-10-21 done'"
run $P "node look.mjs 'http://localhost:8082/?today=2026-10-21'"
block serverlog
served 8008
unserve
