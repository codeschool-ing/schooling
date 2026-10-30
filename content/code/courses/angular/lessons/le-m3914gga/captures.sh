#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 21's captures left, and saves what it
# leaves for lesson 23.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve` and `node server/api.mjs`, each in a terminal of
# its own, the API starting from seed.json; after each save, a wait until the
# dev server has finished the build it caused. The first page that imports a
# package new to the browser is reloaded once by the dev server, as lesson 12
# shows; the student's own tab takes that reload, and a quiet look stands in
# for it.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-vgsphztn
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
first_page() { quiet '~/planner' 'look http://localhost:4200/ --wait 2000'; quiet '~/planner' 'look http://localhost:4200/courses/git --wait 2000'; }
api
first_page

save preferences src/app/preferences.ts
save preferences src/app/course-sessions/course-sessions.ts; w
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do "'check Hide sessions that are done'" --do "'click This week'" --do "'click JavaScript'"
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do "'check Hide sessions that are done'" --do "'go /courses/javascript'"

save persisting src/app/preferences.ts; w
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do "'check Hide sessions that are done'" --do "'go /courses/javascript'"

cap '~/planner' 'npm install @ngrx/store@21.1.1'
cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save ngrx-store src/app/bench/bench.ts
save ngrx-store src/app/app.config.ts
save ngrx-store src/app/app.html
save ngrx-store src/app/app.ts; w; first_page
cap_look http://localhost:4200/ --text "'app-bench p'" --do "'click Add 30'" --do "'click Add 30'" --do "'click Clear'" --do "'click Add 30'"
cap '~/planner' 'rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts src/app/app.config.ts'
cap '~/planner' 'npm uninstall @ngrx/store'

cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "State: a preference store that lasts between visits"'

bg_stop api
bg_stop serve
snapshot le-m3914gga
