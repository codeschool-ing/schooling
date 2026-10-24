#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 7's captures left, and saves what it
# leaves for lesson 9.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve`, running "in a second terminal";
# three seconds after each save for the dev server to rebuild.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-1xtyf9t7
serve
w() { sleep 3; }

save inputs src/app/week-summary/week-summary.ts
save inputs src/app/week-summary/week-summary.html
cap '~/planner' 'npx ng generate component course-card --inline-template --inline-style --skip-tests'
save inputs src/app/course-card/course-card.ts
save inputs src/app/week/week.ts
save inputs src/app/week/week.html; w
cap_look http://localhost:4200/ --today 2026-10-23 --network

cap '~/planner' 'npx ng generate component course-page --skip-tests'
cap '~/planner' 'npx ng generate component session-list --inline-template --inline-style --skip-tests'
save the-course-page src/app/session-list/session-list.ts
save the-course-page src/app/course-page/course-page.ts
save the-course-page src/app/course-page/course-page.html
save the-course-page src/app/app.html
save the-course-page src/app/app.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-course-page

cap '~/planner' 'npx ng generate component session-row --inline-template --inline-style --skip-tests'
save outputs src/app/session-row/session-row.ts
save outputs src/app/session-list/session-list.ts
save outputs src/app/course-page/course-page.ts
save outputs src/app/course-page/course-page.html; w
cap_look http://localhost:4200/ --today 2026-10-23 --a11y main --do "'check 2026-10-24, 50 minutes'"

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save model src/app/bench/bench.ts
save model src/app/app.html
save model src/app/app.ts; w
cap_look http://localhost:4200/ --text app-bench --do "'click 5 more'" --do "'click 5 more'"

cap '~/planner' 'npx ng generate component panel --inline-template --inline-style --skip-tests'
save projection src/app/panel/panel.ts
save projection src/app/week/week.html
save projection src/app/week/week.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --html "'app-week section > *:first-child'"

save queries src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --a11y app-bench --do "'click Write a note'"
cap '~/planner' 'rm -r src/app/bench'
save queries src/app/app.html
save queries src/app/app.ts; w
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error:|Tests '"
save queries src/app/week-summary/week-summary.spec.ts
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error:|Tests '"
cap '~/planner' 'git add -A && git commit -q -m "Inputs, outputs and projection: the course page and its sessions"'

bg_stop serve
snapshot le-zc1x61c7
