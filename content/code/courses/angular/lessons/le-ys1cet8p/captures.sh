#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 12's captures left, and saves what it
# leaves for lesson 14.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve` and `node server/api.mjs`, each in a terminal of
# its own, the API starting from seed.json; after each save, a wait until the
# dev server has finished the build it caused. The first page that imports a
# package new to the browser (rxjs, @angular/core/rxjs-interop, AsyncPipe's
# part of @angular/common) is reloaded once by the dev server, as lesson 12
# shows; the student's own tab takes that reload, and a quiet look stands in
# for it. Where the lesson has the student press Ctrl-C in the API's terminal
# and start it again, the script does both, three seconds into the look and
# three seconds after.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-xe0vp1n6
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
first_page() { quiet '~/planner' 'look http://localhost:4200/ --wait 2000'; }
api

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save observables src/app/bench/bench.ts
save observables src/app/app.html
save observables src/app/app.ts; w; first_page
cap_look http://localhost:4200/ --text app-bench --network --wait 1000

save operators src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --text app-bench --wait 1000

save switch-map src/app/bench/bench.ts 1; w; first_page
cap_look http://localhost:4200/ --text app-bench --network --wait 100 --do "'fill Find a course = J'" --do "'press a'" --do "'press v'"
save switch-map src/app/bench/bench.ts 2; w
cap_look http://localhost:4200/ --text app-bench --network --wait 100 --do "'fill Find a course = J'" --do "'press a'" --do "'press v'" --do "'wait 600'"

save interop src/app/bench/bench.ts; w; first_page
cap_look http://localhost:4200/ --text app-bench

save retry src/app/planner-store.ts; w
( sleep 3; bg_stop api; sleep 3; api ) &
cap_look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --network --do "'wait 5000'" --do "'check 2026-10-24, 50 minutes'" --do "'wait 4000'"
wait

cap '~/planner' 'rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts'
cap '~/planner' 'git status --short'
cap '~/planner' 'git add -A && git commit -q -m "RxJS: retry a save that may work the second time"'

bg_stop api
bg_stop serve
snapshot le-ys1cet8p
