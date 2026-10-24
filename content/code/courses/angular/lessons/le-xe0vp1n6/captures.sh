#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 11's captures left, and saves what it
# leaves for lesson 13.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve` and `node server/api.mjs`, each running "in a
# terminal of its own"; after each save, a wait until the dev server has
# finished the build it caused. Where the lesson has the student press Ctrl-C
# in the API's terminal during a `look --do 'wait 5000'`, the script sends
# that terminal SIGINT three seconds into the look.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-nbpbr5fr
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
ctrl_c_api_soon() { ( sleep 3; bg_stop api ) & }

cap '~/planner' 'mkdir server && git mv public/courses.json server/seed.json'
save the-api server/api.mjs
cap '~/planner' "echo 'server/planner.json' >> .gitignore"
api
cap '~/planner' 'curl -s http://localhost:3000/api/planner | head -c 120; echo' \
  "curl -s -X PATCH http://localhost:3000/api/sessions/5 -d '{\"done\":\"yes\"}'; echo" \
  "curl -s -X PATCH http://localhost:3000/api/sessions/9 -d '{\"done\":true}'; echo"
cap_bg api
save the-api proxy.conf.json
cap '~/planner' 'npx ng config projects.planner.architect.serve.options.proxyConfig proxy.conf.json'
bg_stop serve
serve
cap '~/planner' 'curl -s http://localhost:4200/api/planner | head -c 120; echo'

save http-client src/app/planner-store.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network

cap '~/planner' "sed -i 's/\"minutes\": 50,/\"minutes\": \"50\",/' server/planner.json"
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week
save typed src/app/planner.ts
save typed src/app/planner-store.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week
cap '~/planner' "sed -i 's/\"minutes\": \"50\",/\"minutes\": 50,/' server/planner.json"

save writing src/app/planner-store.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do "'check 2026-10-24, 50 minutes'"
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week-summary
cap '~/planner' "curl -s -X PATCH http://localhost:3000/api/sessions/5 -d '{\"done\":false}'; echo"

save interceptors src/app/requested-by.ts
save interceptors src/app/app.config.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week-summary
cap_bg api

bg_stop api
cap_look http://localhost:4200/ --today 2026-10-23 --text app-week --network
api
ctrl_c_api_soon
cap_look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --do "'wait 5000'" --do "'check 2026-10-24, 50 minutes'"
wait
save errors src/app/planner-store.ts
save errors src/app/course-page/course-page.html; w
api
ctrl_c_api_soon
cap_look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --do "'wait 5000'" --do "'check 2026-10-24, 50 minutes'"
wait
api
quiet '~/planner' 'npx ng test --watch=false > /tmp/anglab/test12.txt 2>&1'
cap '~/planner' 'git add -A && git commit -q -m "HttpClient: the planner talks to its own API"'

bg_stop api
bg_stop serve
snapshot le-xe0vp1n6
