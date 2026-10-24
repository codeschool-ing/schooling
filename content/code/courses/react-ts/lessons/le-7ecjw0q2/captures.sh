#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 19's captures.sh
#
# Works in ~/planner as lesson 19 left it. What is STAGED rather than typed: the
# files ana wrote, put below and shown in the lesson; the API server and Vite's
# servers, which ana runs in terminals of their own and the script starts in the
# background; data/planner.json, deleted before each demonstration; and the
# page's date, Wednesday 21 October 2026, set with --today. The address Vite
# prints for the network, 192.0.2.2, is the lab machine's own.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-166qxdvn
U=http://localhost:5173
T='--today 2026-10-21'
api_start() { lab exec ana "cd ~/planner && (DELAY=${1:-0} setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo \$! > /tmp/api.pid)"; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start

block deps
serve 5173 npm run dev
run "curl -s -o /dev/null $U/ && curl -s -o /dev/null $U/src/main.tsx" > /dev/null
on "look $U/ $T --network | grep -E 'GET /(src|node_modules)' | head -n 12"
on "ls node_modules/.vite/deps | grep -v '\\.map\$'"
stop

block host
serve 5173 npm run dev -- --host
served

block build
stop
on 'npm run build'
on 'ls dist dist/assets'
on 'cat dist/index.html'

block sourcemap
on "npx vite build --sourcemap | grep -E 'assets|built'"
on "tail -c 60 dist/assets/index-*.js; echo"
on "npx vite build --sourcemap hidden > /dev/null && ls dist/assets"
on "tail -c 60 dist/assets/index-*.js; echo"
on "npm run build > /dev/null && ls dist/assets"

block env
put .env <<'ENV'
# Read by Vite in every mode. Only variables starting with VITE_ reach the browser.
VITE_PLANNER_NAME=My study planner
PLANNER_OWNER=ana
ENV
put .env.development <<'ENV'
# Read by `vite` (the development server) on top of .env.
VITE_PLANNER_NAME=My study planner (development)
ENV
put src/env.d.ts <<'TS'
// The variables this app reads from import.meta.env, with their types. Vite's own,
// such as MODE and DEV, are already typed by vite/client.
interface ImportMetaEnv {
  readonly VITE_PLANNER_NAME?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
TS
on "sed -i \"s|<h1>Study planner</h1>|<h1>{import.meta.env.VITE_PLANNER_NAME ?? 'Study planner'}</h1>|\" src/WeekScreen.tsx && grep -n h1 src/WeekScreen.tsx"
on "sed -i '/^const router/i console.log(JSON.stringify(import.meta.env))\\n' src/main.tsx && npx tsc -b && echo no errors"
serve 5173 npm run dev
block env-dev
on "look $U/ $T | sed -n '1,3p'"
block env-build
on "npm run build > /dev/null && grep -o 'My study planner[^\`]*' dist/assets/index-*.js | sort | uniq -c"
on "grep -c PLANNER_OWNER dist/assets/index-*.js"
stop
serve 4173 npm run preview
on "look http://localhost:4173/ $T | sed -n '1,3p'"
stop
block env-clean
on "sed -i '/^console.log(JSON.stringify(import.meta.env))\$/,+1d' src/main.tsx && grep -c console.log src/main.tsx"
on 'npm run lint && npx tsc -b && echo no errors'

api_stop; fresh
lab save after-$(basename "$PWD")
finish
