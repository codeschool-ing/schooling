#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 19's captures left, and saves what it
# leaves for lesson 21.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve` and `node server/api.mjs`, each in
# a terminal of its own, the API starting from seed.json; after each save, a
# wait until the dev server has finished the build it caused.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-7rfxkq5c
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
api

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save attribute src/app/bench/bench.ts
save attribute src/app/app.html
save attribute src/app/app.ts; w
cap_look http://localhost:4200/ --html app-bench --do "'press Tab'" --do "'press Tab'" --do "'press Tab'" --do "'press Tab'" --do "'press Tab'"

cap '~/planner' 'npx ng generate directive autofocus'
save autofocus src/app/autofocus.ts
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|NG0203|Tests '"
save autofocus src/app/autofocus.spec.ts
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|NG0203|Tests '"
save autofocus src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/courses/git --today 2026-10-23 --a11y app-add-session --do "'click Add sessions'"

save structural src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --text app-bench --do "'click Mark done'"

save the-control src/app/aria-invalid.ts
save the-control src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --a11y app-add-session --do "'fill Minutes = 2'" --do "'click Add'"

cap '~/planner' 'rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts'
cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "Directives: focus on arrival, and aria-invalid on every field"'

bg_stop api
bg_stop serve
snapshot le-2z146c5c
