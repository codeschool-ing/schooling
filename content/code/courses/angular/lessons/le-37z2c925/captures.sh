#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of angular, as a script that
# produces them. The output is not committed: lab/fill.py pastes it into the
# lesson's fences.
#
#   sudo bash captures.sh > out.txt && python3 ../../lab/fill.py <section>.md out.txt
#
# It starts from the ~/planner lesson 2's captures left, and saves what it
# leaves for lesson 4. It needs the network for `ng new legacy` and its
# `npm install`.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve`, running "in a second terminal"
# for the look commands, as lesson 2 left it.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-vs2rnyr2
quiet '~' 'rm -rf ~/legacy'
serve

save a-component src/app/week-summary/week-summary.html
save a-component src/app/week-summary/week-summary.css

cap '~/planner' 'npx ng generate component week'
save imports src/app/week/week.html
save imports src/app/app.html
save imports src/app/app.ts
cap '~/planner' 'npx ng build'
save imports src/app/week/week.ts
cap '~/planner' 'npx ng build 2>&1 | tail -3'
sleep 2
cap_look http://localhost:4200/ --html app-week-summary --raw
cap_look http://localhost:4200/ --styles

cap '~' 'npx @angular/cli@21.2.28 new legacy --standalone=false --style=css --ssr=false --zoneless --ai-config=none --skip-install --skip-git'
cap '~/legacy' 'cp ../planner/.npmrc .' "sed 's/\"planner\"/\"legacy\"/' ../planner/package.json > package.json" 'npm install'
cap '~/legacy' 'cat src/app/app-module.ts'
cap '~/legacy' 'cat src/app/app.ts'
cap '~/legacy' 'npx ng generate component session-list'

cap '~/legacy' 'git init -q && git add -A && git commit -q -m "A module-based project"'
cap '~/legacy' 'npx ng generate @angular/core:standalone --mode=convert-to-standalone 2>&1 | tail -n +4' 'git diff'
cap '~/legacy' 'npx ng generate @angular/core:standalone --mode=prune-ng-modules 2>&1 | tail -n +4'
cap '~/legacy' 'npx ng generate @angular/core:standalone --mode=standalone-bootstrap 2>&1 | tail -n +4'
cap '~/legacy' 'cat src/main.ts'
cap '~/legacy' 'npx ng build 2>&1 | tail -3'
cap '~' 'rm -rf ~/legacy'

cap_look http://localhost:4200/
cap_look http://localhost:4200/ --a11y body
cap '~/planner' 'npx ng test --watch=false 2>&1 | tail -9'
cap '~/planner' 'git add -A && git commit -q -m "Standalone components: the week and its summary"'

bg_stop serve
snapshot le-37z2c925
