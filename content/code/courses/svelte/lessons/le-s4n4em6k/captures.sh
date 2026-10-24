#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l18.txt
#   F="python3 ../../lab/fill.py"
#   $F checking-already.md /tmp/l18.txt --blocks install,script,warn,count-js,implicit
#   $F data-types.md /tmp/l18.txt --blocks cfg,types-node,mv-lib,count2
#   $F routes.md /tmp/l18.txt --blocks mv-routes,count3
#   $F components.md /tmp/l18.txt --blocks mv-planner,comp-errors
#   $F generics.md /tmp/l18.txt --blocks zero,typo,typo-check,typo-back
#   $F runtime.md /tmp/l18.txt --blocks rt-api,rt-look
#
# It starts from the project as lesson 17 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; and, at the end, the
# data file put back as Git has it.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 17

bg_stop dev; bg_stop web
R='src/routes/(planner)'
C="$R/courses/[id=slug]"
show() { shown "$1" "$2" "~/planner/${2%#*}"; }

block install
session '~/planner' 'npm install --save-dev svelte-check@4.7.7 typescript@6.0.3'
block script
session '~/planner' "npm pkg set scripts.check='svelte-kit sync && svelte-check'"
show checking-already.md 'src/routes/(info)/about/+page.svelte#1'
block warn
session '~/planner' "npm run check 2>&1 | grep -A3 'about/+page.svelte'"
show checking-already.md 'src/routes/(info)/about/+page.svelte#2'
block count-js
session '~/planner' 'npm run check 2>&1 | tail -8'
block implicit
session '~/planner' "npm run check -- --output machine 2>&1 | grep -c 'implicitly has an'"

block cfg
session '~/planner' 'git mv jsconfig.json tsconfig.json'
block types-node
session '~/planner' 'npm install --save-dev @types/node@22.20.5'
show data-types.md src/lib/types.ts
block mv-lib
session '~/planner' 'git mv src/lib/week.js src/lib/week.ts' 'git mv src/lib/server/check.js src/lib/server/check.ts' 'git mv src/lib/server/planner.js src/lib/server/planner.ts'
show data-types.md src/lib/week.ts
show data-types.md src/lib/server/check.ts
show data-types.md src/lib/server/planner.ts
block count2
session '~/planner' 'npm run check 2>&1 | tail -1'

block mv-routes
session '~/planner' \
  "git mv '$R/+layout.server.js' '$R/+layout.server.ts'" \
  "git mv '$R/+layout.js' '$R/+layout.ts'" \
  "git mv '$C/+page.js' '$C/+page.ts'" \
  "git mv '$C/+page.server.js' '$C/+page.server.ts'" \
  "git mv '$C/+server.js' '$C/+server.ts'" \
  "git mv '$C/sessions.csv/+server.js' '$C/sessions.csv/+server.ts'" \
  'git mv src/routes/planner.json/+server.js src/routes/planner.json/+server.ts' \
  'git mv src/routes/api/sessions/+server.js src/routes/api/sessions/+server.ts' \
  'git mv src/hooks.server.js src/hooks.server.ts'
for f in "$R/+layout.server.ts" "$R/+layout.ts" "$C/+page.ts" "$C/+page.server.ts" "$C/+server.ts" "$C/sessions.csv/+server.ts" src/routes/planner.json/+server.ts src/routes/api/sessions/+server.ts src/app.d.ts src/hooks.server.ts; do
  show routes.md "$f"
done
block count3
session '~/planner' 'npm run check 2>&1 | tail -1'

block mv-planner
session '~/planner' 'git mv src/lib/planner.svelte.js src/lib/planner.svelte.ts' 'git mv src/lib/context.js src/lib/context.ts' 'git mv src/lib/flash.js src/lib/flash.ts'
for f in src/lib/planner.svelte.ts src/lib/context.ts src/lib/flash.ts src/lib/PlannerProvider.svelte src/lib/AddSession.svelte; do
  show components.md "$f"
done
block comp-errors
session '~/planner' 'npm run check 2>&1 | grep -B1 -A3 Error'

show generics.md src/lib/List.svelte
block zero
session '~/planner' 'npm run check 2>&1 | tail -1'
block typo
session '~/planner' "sed -i 's/{session.minutes} min/{session.minuts} min/' '$C/+page.svelte'"
block typo-check
session '~/planner' 'npm run check 2>&1 | grep -A4 Error'
block typo-back
session '~/planner' "sed -i 's/{session.minuts} min/{session.minutes} min/' '$C/+page.svelte'"

bg dev '~/planner' 'npm run dev'; wait_port 5173; sleep 1
block rt-api
session '~/planner' "curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{\"course\":\"spanish\",\"date\":\"2026-10-24\",\"minutes\":\"30\"}' http://localhost:5173/api/sessions"
block rt-look
session '~/planner' 'look http://localhost:5173/courses/spanish | sed -n 1,12p'

quiet '~/planner' 'git checkout data/planner.json; rm -f data/planner.json.new'
done_lesson 18 "TypeScript: svelte-check, typed data, routes with \$types, a generic List"
