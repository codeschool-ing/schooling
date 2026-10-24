#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of angular, as a script that
# produces them. The output is not committed: lab/fill.py pastes it into the
# lesson's fences (lab/redo.sh runs the whole round).
#
# It starts from the ~/planner lesson 4's captures left, and saves what it
# leaves for lesson 6.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve`, running "in a second terminal"; after each save,
# a wait until the dev server has finished the build it caused.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-ja36d9g0
serve
w() { rebuilt; }

save at-if src/app/week-summary/week-summary.html; w
cap_look http://localhost:4200/ --text app-week-summary
cap_look http://localhost:4200/ --html app-week-summary

save at-for src/app/planner.ts
save at-for src/app/week/week.ts
save at-for src/app/week/week.html; w
cap_look http://localhost:4200/ --a11y main

cap '~/planner' 'npx ng generate component bench --skip-tests'
save tracking src/app/app.html
save tracking src/app/app.ts
save tracking src/app/bench/bench.ts
save tracking src/app/bench/bench.html; w
cap_look http://localhost:4200/ --a11y app-bench --do "'fill by id: Git = 25'" --do "'fill by position: Git = 25'" --do "'click Reverse'"

save at-switch src/app/bench/bench.ts
save at-switch src/app/bench/bench.html 1; w
cap_look http://localhost:4200/ --text app-bench --do "'click Mark done'"
save at-switch src/app/bench/bench.html 2
cap '~/planner' 'npx ng build 2>&1 | grep ERROR'

save at-let src/app/week-summary/week-summary.html; w
cap_look http://localhost:4200/ --text app-week-summary

save old-directives src/app/bench/bench.ts
save old-directives src/app/bench/bench.html; w
cap_look http://localhost:4200/ --text app-bench
cap '~/planner' 'git add -A && git commit -q -m "The bench, the old way"'
cap '~/planner' 'npx ng generate @angular/core:control-flow'
cap '~/planner' 'git diff'
cap '~/planner' 'rm -r src/app/bench'
save old-directives src/app/app.html
save old-directives src/app/app.ts; w
cap '~/planner' 'npx ng test --watch=false 2>&1 | grep Tests'
cap '~/planner' 'git add -A && git commit -q -m "Control flow: the course list, and what is left this week"'

bg_stop serve
snapshot le-xkvc03gn
