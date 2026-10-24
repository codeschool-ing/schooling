#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 9's captures left, and saves what it
# leaves for lesson 11.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve`, running "in a second terminal"; after each save,
# a wait until the dev server has finished the build it caused. A test file
# is not part of that build, so nothing waits after one.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-rgrv5qyn
serve
w() { rebuilt; }

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save asking src/app/bench/bench.ts 1
save asking src/app/app.html
save asking src/app/app.ts; w
cap '~/planner' "look http://localhost:4200/ --text body | grep -v '^    at '"
save asking src/app/bench/bench.ts 2; w
cap_look http://localhost:4200/ --text app-bench

save providers src/app/bench/bench.ts
save providers src/app/app.config.ts 2; w
cap_look http://localhost:4200/ --text app-bench

save tokens src/app/today.ts
save tokens src/app/week/week.ts
save tokens src/app/week/week.html; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week
save tokens src/app/week/week.spec.ts 1
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '"
save tokens src/app/week/week.spec.ts 2
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '"

SAVE_MARK=$(builds)
cap '~/planner' 'git checkout -- src/app/app.config.ts'
save hierarchy src/app/bench/bench.ts 1; w
cap_look http://localhost:4200/ --text app-bench --do "'click Add to first'"
save hierarchy src/app/bench/bench.ts 2; w
cap_look http://localhost:4200/ --text app-bench --do "'click Add to first'"

save modifiers src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --text app-bench --do "'click Add to first'" --do "'click Add to second'"

save injection-context src/app/bench/bench.ts 1; w
cap '~/planner' "look http://localhost:4200/ --text app-bench --do 'click Report' | grep -v '^    at '"
save injection-context src/app/bench/bench.ts 2; w
cap_look http://localhost:4200/ --text app-bench --do "'click Report'"

cap '~/planner' 'rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts'
cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "Dependency injection: today is a token"'

bg_stop serve
snapshot le-f2b01efs
