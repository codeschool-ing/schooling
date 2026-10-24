#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 17's captures left, and saves what it
# leaves for lesson 19.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve` and `node server/api.mjs`, each in a terminal of
# its own, the API starting from seed.json; after each save, a wait until the
# dev server has finished the build it caused. Where the lesson has the
# student stop `ng serve` and start it again with --no-hmr, and back, the
# script does the same in the dev server's terminal.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-2qp8bb94
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
api

save guards src/app/course-exists.ts
save guards src/app/app.routes.ts; w
cap_look http://localhost:4200/courses/rust --url --text main
cap_look http://localhost:4200/courses/rust --html title

save leaving src/app/unsaved-work.ts
save leaving src/app/add-session/add-session.ts
save leaving src/app/app.routes.ts; w
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text h2 --do "'fill Minutes = 45'" --do "'click Sessions'"
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text h2 --accept --do "'fill Minutes = 45'" --do "'click Sessions'"
cap_look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text main --do "'fill Date 1 = 2026-10-27'" --do "'click Add'"

cap '~/planner' "npx ng build 2>&1 | sed -n '/Initial chunk/,/Output location/p'"
save lazy-loading src/app/courses.routes.ts
save lazy-loading src/app/app.routes.ts; w
cap '~/planner' "npx ng build 2>&1 | sed -n '/Initial chunk/,/Output location/p'"
cap_look http://localhost:4200/ --scripts --text h2 --do "'click Git'"

save route-providers src/app/area-probe.ts
save route-providers src/app/courses.routes.ts 1
save route-providers src/app/course-page/course-page.ts; w
cap_look http://localhost:4200/ --text h2 --do "'click Git'" --do "'click This week'" --do "'click JavaScript'"
cap '~/planner' 'rm src/app/area-probe.ts && git checkout -- src/app/course-page/course-page.ts'
save route-providers src/app/courses.routes.ts 2; w

save preloading src/app/app.config.ts; w
cap_look http://localhost:4200/ --scripts --text h2

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save defer src/app/bench/chart.ts
save defer src/app/bench/bench.ts
save defer src/app/app.html
save defer src/app/app.ts; w
cap_look http://localhost:4200/ --scripts --text app-bench
cap '~/planner' "npx ng build 2>&1 | sed -n '/Lazy chunk/,/^$/p'"
bg_stop serve
bg serve '~/planner' 'npx ng serve --no-hmr'; wait_log serve 'Watch mode enabled'; wait_port 4200
cap_look http://localhost:4200/ --scripts --text app-bench
cap_look http://localhost:4200/ --scripts --text app-bench --do "'click Show the chart'"
cap '~/planner' 'rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts'
bg_stop serve
serve
cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "Guards, lazy loading and preloading"'

bg_stop api
bg_stop serve
snapshot le-5fs4t3bh
