#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 13 left, and leaves it for lesson 15.
# Every file it writes is taken from this lesson's .md by lab/extract.py; a
# file written twice is put from its first listing and then its second.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - tsconfig.json is changed with `jsonedit`, the edit sqlite-tests.md asks
#     for in an editor; `expo export`'s report goes to /dev/null.
#   - The planner's server, `serve` and later static.mjs run in the
#     background, as from two more terminals.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-vf1dv4yr
P=/home/ana/planner

block install1
run $P 'npx expo install @react-native-async-storage/async-storage'
run $P 'npm install -E @tanstack/query-async-storage-persister@5.105.0 @tanstack/react-query-persist-client@5.105.0'
put cache.md App.tsx $P/App.tsx
put cache.md jest.setup.ts $P/jest.setup.ts
block cachetests
run $P 'npx tsc --noEmit'
run $P 'npx jest --forceExit 2>&1 | tail -5'

put offline-launch.md offline.mjs $P/offline.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'npx -y serve@14.2.6 --single -l 8082 dist'
block offline
run $P "node offline.mjs 'http://localhost:8082/?today=2026-10-21'"
unserve

block install2
run $P 'npx expo install expo-sqlite'
put sqlite.md src/journal.ts $P/src/journal.ts
put sqlite.md src/planState.tsx $P/src/planState.tsx
put sqlite.md src/WeekScreen.tsx $P/src/WeekScreen.tsx
put sqlite.md App.tsx $P/App.tsx

put sqlite-tests.md test-sqlite.tsx $P/test-sqlite.tsx
put sqlite-tests.md jest.setup.ts $P/jest.setup.ts
put sqlite-tests.md test-utils.tsx $P/test-utils.tsx
put sqlite-tests.md __tests__/journal.test.ts $P/__tests__/journal.test.ts
put sqlite-tests.md __tests__/logged.test.tsx $P/__tests__/logged.test.tsx
block nodetypes
run $P 'npx tsc --noEmit'
jsonedit $P tsconfig.json 'c.compilerOptions.types.push("node")'
run $P 'npm install -E -D @types/node@22.20.5'
run $P 'npx tsc --noEmit'
block sqltests
run $P 'npx jest journal logged --verbose --forceExit'
run $P 'npx jest --forceExit 2>&1 | tail -5'

put migrations.md src/journal.ts $P/src/journal.ts
put migrations.md __tests__/journal.test.ts $P/__tests__/journal.test.ts
block migrated
run $P 'npx jest journal --verbose --forceExit'

block wasm
run $P 'npx expo export --platform web 2>&1 | grep -m1 "Unable to resolve"'
put sqlite-web.md metro.config.js $P/metro.config.js
put sqlite-web.md static.mjs $P/static.mjs
put sqlite-web.md journal.mjs $P/journal.mjs
serve $P 8008 'node server.mjs'
quiet $P 'rm -rf dist && EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web'
serve $P 8082 'node static.mjs dist 8082'
block web
run $P 'find dist -name "*.wasm"'
run $P "node journal.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'"
unserve
