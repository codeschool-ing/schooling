#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 13's captures left, and saves what it
# leaves for lesson 15.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown more than once in one section is
# taken by its position); `ng serve` and `node server/api.mjs`, each in a
# terminal of its own, the API starting from seed.json; after each save, a
# wait until the dev server has finished the build it caused. The first page
# that imports @angular/forms is reloaded once by the dev server, as lesson 12
# shows; the student's own tab takes that reload, and a quiet look stands in
# for it.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-ys1cet8p
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
first_page() { quiet '~/planner' 'look http://localhost:4200/ --wait 2000'; }
api

cap '~/planner' 'npx ng generate component add-session --inline-template --inline-style --skip-tests'
save form-control src/app/add-session/add-session.ts
save form-control src/app/course-page/course-page.ts
save form-control src/app/course-page/course-page.html; w; first_page
cap_look http://localhost:4200/ --text app-add-session --do "'fill Minutes = 45'"
cap_look http://localhost:4200/ --text app-add-session --do "'fill Minutes = '"

save form-group src/app/add-session/add-session.ts 1; w
cap_look http://localhost:4200/ --text app-add-session --do "'fill Date = 2026-10-26'" --do "'fill Minutes = 40'"
save form-group src/app/add-session/add-session.ts 2; w
cap '~/planner' 'npx ng build 2>&1 | grep -A4 ERROR'
save form-group src/app/add-session/add-session.ts 1; w

save submitting src/app/planner-store.ts
save submitting src/app/add-session/add-session.ts
save submitting src/app/course-page/course-page.html; w
cap_look http://localhost:4200/ --text app-course-page --do "'fill Date = 2026-10-26'" --do "'fill Minutes = 40'" --do "'click Add'"
cap_look http://localhost:4200/ --text app-course-page --do "'click Add'"

save form-builder src/app/add-session/add-session.ts; w
cap '~/planner' "npx ng build 2>&1 | grep -E 'ERROR|bundle generation'"

save form-array src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/ --text app-course-page --do "'fill Date 1 = 2026-10-27'" --do "'click Another date'" --do "'fill Date 2 = 2026-10-29'" --do "'fill Minutes = 30'" --do "'click Add'"

cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "Reactive forms: add sessions to a course"'

bg_stop api
bg_stop serve
snapshot le-bvchkn96
