#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 18's captures left, and saves what it
# leaves for lesson 20.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve` and `node server/api.mjs`, each in
# a terminal of its own, the API starting from seed.json; after each save, a
# wait until the dev server has finished the build it caused. Where the
# lesson has the student restart `ng serve`, the script does the same in the
# dev server's terminal.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-5fs4t3bh
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
api

save built-in src/app/week/week.ts
save built-in src/app/week/week.html; w
cap_look http://localhost:4200/ --today 2026-10-23 --text "'app-week p'"

cap '~/planner' 'npx ng config projects.planner.i18n.sourceLocale en-GB'
bg_stop serve
serve
cap_look http://localhost:4200/ --today 2026-10-23 --text "'app-week p'"

cap '~/planner' 'npx ng generate pipe minutes'
save your-own src/app/minutes-pipe.ts
save your-own src/app/minutes-pipe.spec.ts
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|Tests '"
save your-own src/app/week/week.spec.ts
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|Tests '"
save your-own src/app/week-summary/week-summary.html
save your-own src/app/week-summary/week-summary.ts
save your-own src/app/course-card/course-card.ts
save your-own src/app/session-row/session-row.ts
save your-own src/app/course-page/course-page.html
save your-own src/app/course-page/course-page.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --text main

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save pure src/app/bench/bench.ts
save pure src/app/app.html
save pure src/app/app.ts; w
cap_look http://localhost:4200/ --text "'app-bench p'" --do "'click Push 10'"
cap_look http://localhost:4200/ --text "'app-bench p'" --do "'click Replace with 10 more'"

save impure src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --text "'app-bench p'" --do "'click Push 10'" --do "'click Do nothing'" --do "'click Do nothing'"

cap '~/planner' 'rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts'
cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "Pipes: dates in British English, and durations in words"'

bg_stop api
bg_stop serve
snapshot le-7rfxkq5c
