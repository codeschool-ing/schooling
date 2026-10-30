#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 14's captures left, and saves what it
# leaves for lesson 16.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve` and `node server/api.mjs`, each in
# a terminal of its own, the API starting from seed.json; after each save, a
# wait until the dev server has finished the build it caused.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-bvchkn96
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
api

save built-in src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/ --text app-add-session --do "'fill Minutes = 2'"
cap_look http://localhost:4200/ --text app-add-session --do "'fill Minutes = '"

save messages src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/ --a11y app-add-session --do "'click Add'"
cap_look http://localhost:4200/ --a11y app-add-session --network --do "'fill Date 1 = 2026-10-26'" --do "'fill Minutes = 2'" --do "'click Add'"

save custom src/app/validators.ts
save custom src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --a11y app-add-session --do "'fill Date 1 = 2026-10-20'" --do "'click Add'"
cap_look http://localhost:4200/ --today 2026-10-23 --a11y app-add-session --do "'fill Date 1 = 2026-10-26'" --do "'click Another date'" --do "'fill Date 2 = 2026-10-26'" --do "'click Add'"

save async src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --a11y app-add-session --network --do "'fill Date 1 = 2026-10-24'" --do "'click Add'"

cap '~/planner' "curl -s -X POST http://localhost:3000/api/sessions -d '{\"courseId\":\"javascript\",\"date\":\"2026-10-26\",\"minutes\":-5}'; echo"
save server-last src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text app-course-page --network --do "'fill Date 1 = 2026-10-26'" --do "'click Another date'" --do "'fill Date 2 = 2026-10-28'" --do "'click Add'"
cap '~/planner' "git add -A && git commit -q -m \"Validators: messages, a day that has gone, repeats, and the server's own check\""

bg_stop api
bg_stop serve
snapshot le-nssf67rv
