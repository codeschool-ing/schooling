#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 6's captures left, and saves what it
# leaves for lesson 8. It needs the network: zone.js is installed from npm.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve`, running "in a second terminal",
# restarted after `npm ci` as a person would after reinstalling; after each
# save, a wait until the dev server has finished the build it caused.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-0z4qr9s9
serve
w() { rebuilt; }

cap '~/planner' 'npx ng generate component bench --skip-tests --inline-template --inline-style'
save what-it-does src/app/bench/bench.ts
save what-it-does src/app/app.html
save what-it-does src/app/app.ts; w
cap_look http://localhost:4200/ --text app-bench --do "'click Do nothing'"

save zone-js src/app/bench/bench.ts
cap '~/planner' 'git add -A && git commit -q -m "A bench for change detection"'
bg_stop serve
cap '~/planner' 'npm install zone.js@0.16.3'
cap '~/planner' 'npm audit 2>&1 | head -12'
save zone-js src/main.ts
save zone-js src/app/app.config.ts
serve
cap_look http://localhost:4200/ --text app-bench --wait 1000

bg_stop serve
cap '~/planner' 'git status --short' 'git checkout -- .' 'npm ci'
serve
cap_look http://localhost:4200/ --text app-bench --wait 1000

save expression-changed src/app/bench/bench.ts; w
cap '~/planner' "look http://localhost:4200/ --text app-bench | grep -v '^    at '"

cap '~/planner' 'rm -r src/app/bench'
save choosing src/app/app.html
save choosing src/app/app.ts
save choosing src/app/week/week.ts
save choosing src/app/week-summary/week-summary.ts; w
cap '~/planner' 'npx ng config projects.planner.schematics.@schematics/angular:component.changeDetection OnPush'
cap_look http://localhost:4200/ --today 2026-10-23 --text main
cap '~/planner' 'npx ng test --watch=false 2>&1 | grep Tests'
cap '~/planner' 'git add -A && git commit -q -m "Change detection: OnPush everywhere, no zone.js"'

bg_stop serve
snapshot le-1xtyf9t7
