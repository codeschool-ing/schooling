#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 10's captures left, and saves what it
# leaves for lesson 12.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve`, running "in a second terminal"; after each save,
# a wait until the dev server has finished the build it caused.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-f2b01efs
serve
w() { rebuilt; }
tick() { cap_look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do "'check 2026-10-24, 50 minutes'"; }

tick

cap '~/planner' 'npx ng generate service planner-store'
save a-service src/app/planner-store.ts 2

save using-it src/app/week/week.ts
save using-it src/app/week/week.html
save using-it src/app/course-page/course-page.ts
save using-it src/app/course-page/course-page.html; w
tick

save read-only src/app/course-page/course-page.ts 1; w
cap '~/planner' 'npx ng build 2>&1 | grep -A4 ERROR'
save read-only src/app/course-page/course-page.ts 2; w

save what-belongs src/app/planner-store.ts
save what-belongs src/app/week/week.ts
save what-belongs src/app/week/week.html; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '"

save scope src/app/course-page/course-page.ts 1; w
tick
save scope src/app/course-page/course-page.ts 2; w
cap '~/planner' 'git add -A && git commit -q -m "Services: one store for the planner"'

bg_stop serve
snapshot le-nbpbr5fr
