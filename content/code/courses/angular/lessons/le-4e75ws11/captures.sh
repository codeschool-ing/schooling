#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 15's captures left, and leaves it as it
# found it, so lesson 17 starts from the same snapshot.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve` and `node server/api.mjs`, each in
# a terminal of its own, the API starting from seed.json; after each save, a
# wait until the dev server has finished the build it caused. The first page
# that imports @angular/forms/signals is reloaded once by the dev server, as
# lesson 12 shows; the student's own tab takes that reload, and a quiet look
# stands in for it.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-nssf67rv
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
first_page() { quiet '~/planner' 'look http://localhost:4200/ --wait 2000'; }
api

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save ng-model src/app/bench/bench.ts
save ng-model src/app/app.html
save ng-model src/app/app.ts; w
cap_look http://localhost:4200/ --text app-bench --do "'fill Day = 2026-10-26'" --do "'fill Length in minutes = 45'"

save in-the-template src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --text app-bench --do "'fill Length in minutes = 2'" --do "'click Check'"

save the-catch src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --text app-bench

save signal-forms src/app/bench/bench.ts; w; first_page
cap_look http://localhost:4200/ --text app-bench --do "'fill Length in minutes = 2'"
cap_look http://localhost:4200/ --text app-bench --do "'fill Day = 2026-10-26'" --do "'fill Length in minutes = 45'"
cap_look http://localhost:4200/ --html "'app-bench form'"

cap '~/planner' 'rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts'
cap '~/planner' 'git status --short'

bg_stop api
bg_stop serve
snapshot le-4e75ws11
