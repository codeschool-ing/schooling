#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 20's captures left, and saves what it
# leaves for lesson 22.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve` and `node server/api.mjs`, each in
# a terminal of its own, the API starting from seed.json, and `ng serve`
# started after `ng add` changed angular.json, as the lesson says; after each
# save, a wait until the dev server has finished the build it caused. The
# first page that imports a package new to the browser is reloaded once by
# the dev server, as lesson 12 shows; the student's own tab takes that
# reload, and a quiet look stands in for it.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-2z146c5c
quiet '~/planner' 'rm -f server/planner.json'
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
first_page() { quiet '~/planner' 'look http://localhost:4200/ --wait 2000'; quiet '~/planner' 'look http://localhost:4200/courses/git/add --wait 2000'; }
api

cap '~/planner' "npx ng build 2>&1 | grep -E 'Initial total|courses-routes'"
cap '~/planner' 'npx ng add @angular/material@21.2.14 --skip-confirmation --interactive=false'
cap '~/planner' 'git status --short'
cap '~/planner' 'cat src/material-theme.scss'
cap '~/planner' 'git checkout -- src/index.html'
serve

save components src/app/session-row/session-row.ts; w; first_page
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --a11y app-course-sessions --do "'check Sat 24 Oct, 50 minutes'"

save a-dialog src/app/confirm-leave/confirm-leave.ts
save a-dialog src/app/unsaved-work.ts; w; first_page
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --url --a11y body --do "'fill Minutes = 45'" --do "'click Sessions'"
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --a11y "'app-course-page nav'" --do "'fill Minutes = 45'" --do "'click Sessions'" --do "'press Escape'"
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text h2 --do "'fill Minutes = 45'" --do "'click Sessions'" --do "'click Leave'"

save announcing src/app/add-session/add-session.ts; w; first_page
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --html .cdk-live-announcer-element --do "'fill Date 1 = 2026-10-27'" --do "'click Another date'" --do "'fill Date 2 = 2026-10-29'" --do "'click Add'"

cap '~/planner' "npx ng build 2>&1 | grep -E 'Initial total|courses-routes'"
cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "Material and the CDK: a checkbox, a dialog, an announcement"'

bg_stop api
bg_stop serve
snapshot le-vgsphztn
